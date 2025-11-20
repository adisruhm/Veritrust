;; VeriTrust - Decentralized Credential Verification System
;; Version: v1.0
;; Description: Enables verified institutions to issue and verify credentials on-chain.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CONSTANTS & ERRORS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-constant ERR-NOT-ADMIN (err u100))
(define-constant ERR-NOT-INSTITUTION (err u101))
(define-constant ERR-CREDENTIAL-NOT-FOUND (err u102))
(define-constant ERR-ALREADY-ISSUED (err u103))
(define-constant ERR-NOT-OWNER (err u104))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DATA STRUCTURES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-data-var admin principal tx-sender)
(define-data-var credential-counter uint u0)

;; Registered issuing institutions
(define-map institutions
  {issuer: principal}
  {verified: bool}
)

;; credential-id -> credential data
(define-map credentials
  {id: uint}
  {
    issuer: principal,
    recipient: principal,
    credential-name: (string-ascii 64),
    description: (string-ascii 140),
    uri: (string-ascii 128), ;; optional off-chain reference
    issued-at: uint,
    is-active: bool
  }
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ADMIN CONTROLS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-public (add-institution (issuer principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR-NOT-ADMIN)
    (map-set institutions {issuer: issuer} {verified: true})
    (print {event: "institution-added", issuer: issuer})
    (ok true)
  )
)

(define-public (remove-institution (issuer principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR-NOT-ADMIN)
    (map-delete institutions {issuer: issuer})
    (print {event: "institution-removed", issuer: issuer})
    (ok true)
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CREDENTIAL ISSUANCE & MANAGEMENT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-public (issue-credential (recipient principal) (credential-name (string-ascii 64)) (description (string-ascii 140)) (uri (string-ascii 128)))
  ;; Changed map-get to map-get? for optional lookup
  (let ((issuer-info (map-get? institutions {issuer: tx-sender})))
    (begin
      (asserts! (is-some issuer-info) ERR-NOT-INSTITUTION)
      (let ((id (+ (var-get credential-counter) u1)))
        (begin
          (map-set credentials {id: id}
            {
              issuer: tx-sender,
              recipient: recipient,
              credential-name: credential-name,
              description: description,
              uri: uri,
              issued-at: stacks-block-height,
              is-active: true
            })
          (var-set credential-counter id)
          (print {event: "credential-issued", id: id, issuer: tx-sender, recipient: recipient})
          (ok id)
        )
      )
    )
  )
)

(define-public (revoke-credential (id uint))
  (let ((cred (unwrap! (map-get? credentials {id: id}) ERR-CREDENTIAL-NOT-FOUND)))
    (begin
      (asserts! (is-eq tx-sender (get issuer cred)) ERR-NOT-INSTITUTION)
      (map-set credentials {id: id} (merge cred {is-active: false}))
      (print {event: "credential-revoked", id: id})
      (ok true)
    )
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; READ-ONLY FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-read-only (get-credential (id uint))
  (map-get? credentials {id: id})
)

(define-read-only (get-total-credentials)
  (var-get credential-counter)
)

(define-read-only (verify-credential (id uint))
  (let ((cred (map-get? credentials {id: id})))
    (if (is-some cred)
        (let ((data (unwrap-panic cred)))
          (if (get is-active data)
              (ok {issuer: (get issuer data), recipient: (get recipient data), name: (get credential-name data), valid: true})
              (ok {issuer: (get issuer data), recipient: (get recipient data), name: (get credential-name data), valid: false})
          )
        )
        (err u404)
    )
  )
)

(define-read-only (is-institution (issuer principal))
  (is-some (map-get? institutions {issuer: issuer}))
)
