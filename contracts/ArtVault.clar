;; ArtVault: Digital Art Authentication Platform
;; Version: 1.0.0
(define-constant ERR-NOT-AUTHORIZED (err u1))
(define-constant ERR-ARTWORK-NOT-FOUND (err u2))
(define-constant ERR-ALREADY-REGISTERED (err u3))
(define-constant ERR-INVALID-AVAILABILITY (err u4))
(define-constant ERR-INVALID-EDITION (err u5))
(define-constant ERR-INVALID-CATEGORY (err u6))
(define-constant ERR-INVALID-AUTHENTICITY (err u7))
(define-constant ERR-INVALID-TITLE (err u8))
(define-constant ERR-INVALID-DESCRIPTION (err u9))
(define-constant MIN-EDITION u1)
(define-data-var next-artwork-id uint u1)
(define-map artworks
    uint
    {
        creator: principal,
        artwork-title: (string-utf8 50),
        artwork-description: (string-utf8 200),
        art-category: (string-utf8 10),
        authenticity: (string-utf8 20),
        availability: (string-utf8 10),
        edition-number: uint
    }
)
(define-private (validate-category (category (string-utf8 10)))
    (or 
        (is-eq category u"Digital")
        (is-eq category u"Painting")
        (is-eq category u"Photography")
        (is-eq category u"Sculpture")
        (is-eq category u"Animation")
        (is-eq category u"Generative")
    )
)
(define-private (validate-authenticity (authenticity (string-utf8 20)))
    (or 
        (is-eq authenticity u"Original")
        (is-eq authenticity u"Limited Edition")
        (is-eq authenticity u"Authorized Copy")
        (is-eq authenticity u"Reproduction")
        (is-eq authenticity u"Derivative")
    )
)
(define-private (validate-text-length (text (string-utf8 200)) (min-length uint) (max-length uint))
    (let 
        (
            (text-length (len text))
        )
        (and 
            (>= text-length min-length)
            (<= text-length max-length)
        )
    )
)
(define-public (register-artwork 
    (artwork-title (string-utf8 50))
    (artwork-description (string-utf8 200))
    (art-category (string-utf8 10))
    (authenticity (string-utf8 20))
    (edition-number uint)
)
    (let
        (
            (artwork-id (var-get next-artwork-id))
        )
        (asserts! (validate-text-length artwork-title u3 u50) ERR-INVALID-TITLE)
        (asserts! (validate-text-length artwork-description u10 u200) ERR-INVALID-DESCRIPTION)
        (asserts! (>= edition-number MIN-EDITION) ERR-INVALID-EDITION)
        (asserts! (validate-category art-category) ERR-INVALID-CATEGORY)
        (asserts! (validate-authenticity authenticity) ERR-INVALID-AUTHENTICITY)
        
        (map-set artworks artwork-id {
            creator: tx-sender,
            artwork-title: artwork-title,
            artwork-description: artwork-description,
            art-category: art-category,
            authenticity: authenticity,
            availability: u"listed",
            edition-number: edition-number
        })
        (var-set next-artwork-id (+ artwork-id u1))
        (ok artwork-id)
    )
)
(define-public (delist-artwork (artwork-id uint))
    (let
        (
            (artwork (unwrap! (map-get? artworks artwork-id) ERR-ARTWORK-NOT-FOUND))
        )
        (asserts! (is-eq tx-sender (get creator artwork)) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq (get availability artwork) u"listed") ERR-INVALID-AVAILABILITY)
        (ok (map-set artworks artwork-id (merge artwork { availability: u"unlisted" })))
    )
)
(define-read-only (get-artwork (artwork-id uint))
    (ok (map-get? artworks artwork-id))
)
(define-read-only (get-creator (artwork-id uint))
    (ok (get creator (unwrap! (map-get? artworks artwork-id) ERR-ARTWORK-NOT-FOUND)))
)