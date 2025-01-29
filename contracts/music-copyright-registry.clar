;; Music Copyright Registry Contract

(define-non-fungible-token music-copyright uint)

(define-map copyright-info
  { copyright-id: uint }
  {
    owner: principal,
    title: (string-utf8 100),
    artist: (string-utf8 100),
    composer: (string-utf8 100),
    release-date: uint,
    isrc: (string-ascii 12),
    additional-info: (optional (string-utf8 1000))
  }
)

(define-data-var copyright-id-nonce uint u0)

(define-constant CONTRACT_OWNER tx-sender)

(define-read-only (get-last-copyright-id)
  (ok (var-get copyright-id-nonce))
)

(define-read-only (get-copyright-info (copyright-id uint))
  (map-get? copyright-info { copyright-id: copyright-id })
)

(define-public (register-copyright
  (title (string-utf8 100))
  (artist (string-utf8 100))
  (composer (string-utf8 100))
  (release-date uint)
  (isrc (string-ascii 12))
  (additional-info (optional (string-utf8 1000)))
)
  (let
    ((new-copyright-id (+ (var-get copyright-id-nonce) u1)))
    (try! (nft-mint? music-copyright new-copyright-id tx-sender))
    (map-set copyright-info
      { copyright-id: new-copyright-id }
      {
        owner: tx-sender,
        title: title,
        artist: artist,
        composer: composer,
        release-date: release-date,
        isrc: isrc,
        additional-info: additional-info
      }
    )
    (var-set copyright-id-nonce new-copyright-id)
    (ok new-copyright-id)
  )
)

(define-public (transfer-copyright (copyright-id uint) (recipient principal))
  (let
    ((owner (unwrap! (nft-get-owner? music-copyright copyright-id) (err u404))))
    (asserts! (is-eq tx-sender owner) (err u403))
    (try! (nft-transfer? music-copyright copyright-id tx-sender recipient))
    (ok (map-set copyright-info
      { copyright-id: copyright-id }
      (merge (unwrap! (map-get? copyright-info { copyright-id: copyright-id }) (err u404))
             { owner: recipient })
    ))
  )
)

(define-public (update-copyright-info
  (copyright-id uint)
  (new-title (optional (string-utf8 100)))
  (new-artist (optional (string-utf8 100)))
  (new-composer (optional (string-utf8 100)))
  (new-additional-info (optional (string-utf8 1000)))
)
  (let
    ((current-info (unwrap! (map-get? copyright-info { copyright-id: copyright-id }) (err u404))))
    (asserts! (is-eq tx-sender (get owner current-info)) (err u403))
    (ok (map-set copyright-info
      { copyright-id: copyright-id }
      (merge current-info
        {
          title: (default-to (get title current-info) new-title),
          artist: (default-to (get artist current-info) new-artist),
          composer: (default-to (get composer current-info) new-composer),
          additional-info: (match new-additional-info
            info (some info)
            (get additional-info current-info)
          )
        }
      )
    ))
  )
)

