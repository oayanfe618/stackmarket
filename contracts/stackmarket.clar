;; stackmarket.clar
;; Decentralized marketplace smart contract on Stacks

;; --------------------------------
;; ERRORS
;; --------------------------------
(define-constant ERR_NOT_FOUND u100)
(define-constant ERR_INVALID_AMOUNT u101)
(define-constant ERR_NOT_SELLER u102)
(define-constant ERR_NOT_BUYER u103)
(define-constant ERR_ALREADY_COMPLETED u104)
(define-constant ERR_REFUND_NOT_ALLOWED u105)
(define-constant ERR_ALREADY_LISTED u106)
(define-constant ERR_NO_FUNDS u107)

;; --------------------------------
;; DATA VARIABLES
;; --------------------------------
(define-data-var owner principal tx-sender)
(define-data-var next-item-id uint u0)
(define-data-var total-sales uint u0)
(define-data-var total-users uint u0)

;; --------------------------------
;; MAPS
;; --------------------------------
(define-map items
  uint
  (tuple
    (seller principal)
    (title (string-ascii 64))
    (description (string-ascii 256))
    (price uint)
    (stock uint)
    (active bool)
  )
)

(define-map orders
  uint
  (tuple
    (buyer principal)
    (item-id uint)
    (amount uint)
    (confirmed bool)
    (refunded bool)
  )
)

(define-map ratings
  principal
  (tuple
    (total-rating uint)
    (num-ratings uint)
  )
)

(define-data-var next-order-id uint u0)

;; --------------------------------
;; EVENTS
;; --------------------------------

;; --------------------------------
;; PRIVATE HELPERS
;; --------------------------------
(define-private (get-rating (seller principal))
  (let ((r (map-get? ratings seller)))
    (match r
      rate (/ (get total-rating rate) (get num-ratings rate))
      u0))
)

;; --------------------------------
;; PUBLIC FUNCTIONS
;; --------------------------------

;; List an item for sale
(define-public (list-item (title (string-ascii 64)) (description (string-ascii 256)) (price uint) (stock uint))
  (if (and (> price u0) (> stock u0))
      (let ((id (+ (var-get next-item-id) u1)))
        (map-set items id
          (tuple
            (seller tx-sender)
            (title title)
            (description description)
            (price price)
            (stock stock)
            (active true)))
        (var-set next-item-id id)
        (ok (tuple (item-id id) (price price))))
      (err ERR_INVALID_AMOUNT))
)

;; Buy an item (creates an escrow)
(define-public (buy-item (item-id uint) (quantity uint))
  (let ((item (map-get? items item-id)))
    (match item
      i
        (if (and (get active i) (> quantity u0) (<= quantity (get stock i)))
            (let ((cost (* (get price i) quantity))
                  (order-id (+ (var-get next-order-id) u1)))
              (try! (stx-transfer? cost tx-sender contract-caller))
              (map-set orders order-id
                (tuple
                  (buyer tx-sender)
                  (item-id item-id)
                  (amount cost)
                  (confirmed false)
                  (refunded false)))
              (map-set items item-id
                (tuple
                  (seller (get seller i))
                  (title (get title i))
                  (description (get description i))
                  (price (get price i))
                  (stock (- (get stock i) quantity))
                  (active (get active i))))
              (var-set next-order-id order-id)
              (ok (tuple (order-id order-id) (cost cost))))
            (err ERR_INVALID_AMOUNT))
      (err ERR_NOT_FOUND)))
)

;; Confirm order (buyer releases payment to seller)
(define-public (confirm-order (order-id uint))
  (let ((o (map-get? orders order-id)))
    (match o
      ord
        (if (and (is-eq tx-sender (get buyer ord)) (not (get confirmed ord)) (not (get refunded ord)))
            (let ((item (map-get? items (get item-id ord))))
              (match item
                i
                  (begin
                    (try! (stx-transfer? (get amount ord) contract-caller (get seller i)))
                    (map-set orders order-id
                      (tuple
                        (buyer (get buyer ord))
                        (item-id (get item-id ord))
                        (amount (get amount ord))
                        (confirmed true)
                        (refunded false)))
                    (var-set total-sales (+ (var-get total-sales) (get amount ord)))
                    (ok "Order confirmed"))
                (err ERR_NOT_FOUND)))
            (err ERR_NOT_BUYER))
      (err ERR_NOT_FOUND)))
)

;; Refund order (only buyer before confirmation)
(define-public (refund-order (order-id uint))
  (let ((o (map-get? orders order-id)))
    (match o
      ord
        (if (and (is-eq tx-sender (get buyer ord)) (not (get confirmed ord)) (not (get refunded ord)))
            (begin
              (try! (stx-transfer? (get amount ord) contract-caller tx-sender))
              (map-set orders order-id
                (tuple
                  (buyer (get buyer ord))
                  (item-id (get item-id ord))
                  (amount (get amount ord))
                  (confirmed false)
                  (refunded true)))
              (ok "Refund successful"))
            (err ERR_REFUND_NOT_ALLOWED))
      (err ERR_NOT_FOUND)))
)

;; Rate a seller after purchase
(define-public (rate-seller (order-id uint) (score uint))
  (let ((o (map-get? orders order-id)))
    (match o
      ord
        (if (and (is-eq tx-sender (get buyer ord)) (get confirmed ord) (<= score u5))
            (let ((item (map-get? items (get item-id ord))))
              (match item
                i
                  (let ((r (map-get? ratings (get seller i))))
                    (begin
                      (if (is-some r)
                        (let ((existing (unwrap-panic r)))
                          (map-set ratings (get seller i)
                            (tuple
                              (total-rating (+ (get total-rating existing) score))
                              (num-ratings (+ (get num-ratings existing) u1)))))
                        (map-set ratings (get seller i)
                          (tuple
                            (total-rating score)
                            (num-ratings u1))))
                      (ok "Seller rated")))
                (err ERR_NOT_FOUND)))
            (err ERR_NOT_BUYER))
      (err ERR_NOT_FOUND)))
)

;; --------------------------------
;; READ-ONLY FUNCTIONS
;; --------------------------------
(define-read-only (get-item (id uint))
  (map-get? items id)
)

(define-read-only (get-order (id uint))
  (map-get? orders id)
)

(define-read-only (get-seller-rating (seller principal))
  (get-rating seller)
)

(define-read-only (get-total-sales)
  (var-get total-sales)
)
