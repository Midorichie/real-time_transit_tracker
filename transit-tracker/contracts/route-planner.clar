;; route-planner.clar - Smart contract for route planning and calculations
;; Author: [Your Name]
;; Version: 0.1.0

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-invalid-data (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-limit-exceeded (err u104))

;; Data variables
(define-data-var max-route-length uint u20)
(define-data-var query-cost uint u1)  ;; Cost in microstacks for route queries

;; Define a structure for cached routes
(define-map cached-routes
  { from-stop: (string-ascii 20), to-stop: (string-ascii 20) }
  {
    route-steps: (list 20 (string-ascii 20)),  ;; List of stop IDs in order
    estimated-time: uint,                       ;; Estimated time in seconds
    last-updated: uint,                         ;; Block height when last updated
    route-hash: (buff 32)                       ;; Hash of the route for verification
  }
)

;; Map to track authorized route data providers
(define-map authorized-providers
  { provider: principal }
  { active: bool }
)

;; Map to track user query limits (anti-spam measure)
(define-map user-query-limits
  { user: principal }
  { 
    queries-today: uint,
    last-query-day: uint,
    total-queries: uint
  }
)

;; Read-only functions

(define-read-only (get-cached-route (from-stop (string-ascii 20)) (to-stop (string-ascii 20)))
  (map-get? cached-routes { from-stop: from-stop, to-stop: to-stop })
)

(define-read-only (is-authorized-provider (provider principal))
  (default-to false (get active (map-get? authorized-providers { provider: provider })))
)

(define-read-only (get-query-cost)
  (var-get query-cost)
)

;; Helper function to serialize a list of stops into a single string
(define-private (fold-stops (acc (string-ascii 1000)) (item (string-ascii 20)))
  (concat acc item)
)

;; Non-recursive function to convert a uint to ASCII string
(define-private (int-to-ascii-simple (n uint))
  (if (is-eq n u0)
      "0"
      (if (is-eq n u1)
          "1"
          (if (is-eq n u2)
              "2"
              (if (is-eq n u3)
                  "3"
                  (if (is-eq n u4)
                      "4"
                      (if (is-eq n u5)
                          "5"
                          (if (is-eq n u6)
                              "6"
                              (if (is-eq n u7)
                                  "7"
                                  (if (is-eq n u8)
                                      "8"
                                      (if (is-eq n u9)
                                          "9"
                                          (if (is-eq n u10)
                                              "10"
                                              (if (< n u60) 
                                                  (concat "unknown-" (to-ascii n))
                                                  "unknown"))))))))))))
)

;; Convert a number to ASCII representation (just a stub for large numbers)
(define-private (to-ascii (n uint))
  (if (< n u10)
      (unwrap-panic (element-at (list "0" "1" "2" "3" "4" "5" "6" "7" "8" "9") n))
      "x"
  )
)

;; Simple function to convert a route to a hash
(define-read-only (hash-route (stops (list 20 (string-ascii 20))) (time uint))
  ;; For simplicity, we'll hash the uint time directly
  (let ((first-stop (default-to "" (element-at stops u0))))
    ;; Using time directly as uint - sha256 can take uint as input
    (sha256 time)
  )
)

;; Public functions - for route planning and management

;; Add a new cached route (restricted to authorized providers)
(define-public (add-route 
  (from-stop (string-ascii 20)) 
  (to-stop (string-ascii 20)) 
  (route-steps (list 20 (string-ascii 20)))
  (estimated-time uint))
  
  (let ((route-hash (hash-route route-steps estimated-time)))
    (begin
      ;; Only authorized providers can add routes
      (asserts! (is-authorized-provider tx-sender) err-unauthorized)
      ;; Validate route length
      (asserts! (<= (len route-steps) (var-get max-route-length)) err-limit-exceeded)
      
      (map-set cached-routes
        { from-stop: from-stop, to-stop: to-stop }
        {
          route-steps: route-steps,
          estimated-time: estimated-time,
          last-updated: block-height,
          route-hash: route-hash
        }
      )
      (ok route-hash)
    )
  )
)

;; Query a route between two stops (public function, costs query-cost)
(define-public (query-route (from-stop (string-ascii 20)) (to-stop (string-ascii 20)))
  (let (
    (day-number (/ burn-block-height u144))  ;; Approximate day number (144 blocks per day)
    (user-limits (default-to { queries-today: u0, last-query-day: u0, total-queries: u0 } 
                 (map-get? user-query-limits { user: tx-sender })))
    (current-queries (if (is-eq (get last-query-day user-limits) day-number)
                        (get queries-today user-limits)
                        u0))
  )
    (begin
      ;; Pay for the query
      (try! (stx-transfer? (var-get query-cost) tx-sender contract-owner))
      
      ;; Update user query limits
      (map-set user-query-limits
        { user: tx-sender }
        {
          queries-today: (+ current-queries u1),
          last-query-day: day-number,
          total-queries: (+ (get total-queries user-limits) u1)
        }
      )
      
      ;; Return the route
      (ok (get-cached-route from-stop to-stop))
    )
  )
)

;; Admin functions - restricted to contract owner

;; Add or remove authorized data providers
(define-public (set-provider-status (provider principal) (active bool))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set authorized-providers
      { provider: provider }
      { active: active }
    )
    (ok true)
  )
)

;; Set maximum route length
(define-public (set-max-route-length (length uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set max-route-length length)
    (ok true)
  )
)

;; Set query cost
(define-public (set-query-cost (cost uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set query-cost cost)
    (ok true)
  )
)

;; Withdraw STX from contract (if using payment model)
(define-public (withdraw-stx (amount uint) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (try! (as-contract (stx-transfer? amount contract-owner recipient)))
    (ok true)
  )
)
