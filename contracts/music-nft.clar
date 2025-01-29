;; Music NFT Contract

(define-non-fungible-token music-nft uint)

(define-map nft-metadata
  { token-id: uint }
  {
    copyright-id: uint,
    title: (string-utf8 100),
    artist: (string-utf8 100),
    album: (optional (string-utf8 100)),
    genre: (string-ascii 50),
    release-date: uint,
    cover-art: (optional (string-utf8 256)),
    license-terms: (string-utf8 1000)
  }
)

(define-data-var token-id-nonce uint u0)

(define-constant CONTRACT_OWNER tx-sender)

(define-read-only (get-last-token-id)
  (ok (var-get token-id-nonce))
)

(define-read-only (get-token-uri (token-id uint))
  (ok none)
)

(define-read-only (get-owner (token-id uint))
  (ok (nft-get-owner? music-nft token-id))
)

(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) (err u403))
    (nft-transfer? music-nft token-id sender recipient)
  )
)

(define-public (mint-music-nft
  (copyright-id uint)
  (title (string-utf8 100))
  (artist (string-utf8 100))
  (album (optional (string-utf8 100)))
  (genre (string-ascii 50))
  (release-date uint)
  (cover-art (optional (string-utf8 256)))
  (license-terms (string-utf8 1000))
)
  (let
    ((new-token-id (+ (var-get token-id-nonce) u1))
     (copyright-info (unwrap! (contract-call? .music-copyright-registry get-copyright-info copyright-id) (err u404))))
    (asserts! (is-eq tx-sender (get owner copyright-info)) (err u403))
    (try! (nft-mint? music-nft new-token-id tx-sender))
    (map-set nft-metadata
      { token-id: new-token-id }
      {
        copyright-id: copyright-id,
        title: title,
        artist: artist,
        album: album,
        genre: genre,
        release-date: release-date,
        cover-art: cover-art,
        license-terms: license-terms
      }
    )
    (var-set token-id-nonce new-token-id)
    (ok new-token-id)
  )
)

(define-read-only (get-nft-metadata (token-id uint))
  (map-get? nft-metadata { token-id: token-id })
)

