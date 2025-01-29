;; Music Licensing Contract

(define-map licenses
  { license-id: uint }
  {
    copyright-id: uint,
    licensee: principal,
    license-type: (string-ascii 20),
    start-date: uint,
    end-date: uint,
    territory: (string-ascii 50),
    fee: uint,
    royalty-rate: uint,
    status: (string-ascii 10)
  }
)

(define-data-var license-id-nonce uint u0)

(define-constant CONTRACT_OWNER tx-sender)

(define-read-only (get-license (license-id uint))
  (map-get? licenses { license-id: license-id })
)

(define-public (create-license
  (copyright-id uint)
  (licensee principal)
  (license-type (string-ascii 20))
  (start-date uint)
  (end-date uint)
  (territory (string-ascii 50))
  (fee uint)
  (royalty-rate uint)
)
  (let
    ((new-license-id (+ (var-get license-id-nonce) u1))
     (copyright-owner (unwrap! (contract-call? .music-copyright-registry get-copyright-info copyright-id) (err u404))))
    (asserts! (is-eq tx-sender (get owner copyright-owner)) (err u403))
    (map-set licenses
      { license-id: new-license-id }
      {
        copyright-id: copyright-id,
        licensee: licensee,
        license-type: license-type,
        start-date: start-date,
        end-date: end-date,
        territory: territory,
        fee: fee,
        royalty-rate: royalty-rate,
        status: "active"
      }
    )
    (var-set license-id-nonce new-license-id)
    (ok new-license-id)
  )
)

(define-public (update-license-status (license-id uint) (new-status (string-ascii 10)))
  (let
    ((license (unwrap! (map-get? licenses { license-id: license-id }) (err u404)))
     (copyright-owner (unwrap! (contract-call? .music-copyright-registry get-copyright-info (get copyright-id license)) (err u404))))
    (asserts! (or (is-eq tx-sender (get owner copyright-owner)) (is-eq tx-sender CONTRACT_OWNER)) (err u403))
    (ok (map-set licenses
      { license-id: license-id }
      (merge license { status: new-status })
    ))
  )
)

(define-read-only (get-license-status (license-id uint))
  (match (map-get? licenses { license-id: license-id })
    license (ok (get status license))
    (err u404)
  )
)
