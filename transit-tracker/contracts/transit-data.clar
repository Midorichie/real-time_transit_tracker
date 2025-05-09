;; transit-data.clar - Smart contract for transit data storage and retrieval
;; Author: [Your Name]
;; Version: 0.1.0

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-invalid-data (err u102))

;; Data variables
(define-data-var last-update uint u0)  ;; Timestamp of last data update

;; Data maps
(define-map transit-stops
  { stop-id: (string-ascii 20) }
  {
    name: (string-ascii 100),
    latitude: int,
    longitude: int,
    active: bool
  }
)

(define-map transit-vehicles
  { vehicle-id: (string-ascii 20) }
  {
    route-id: (string-ascii 20),
    latitude: int,
    longitude: int,
    last-position-update: uint,
    status: (string-ascii 20)  ;; "in-service", "out-of-service", etc.
  }
)

(define-map transit-routes
  { route-id: (string-ascii 20) }
  {
    name: (string-ascii 100),
    stops: (list 20 (string-ascii 20)),
    active: bool
  }
)

;; Read-only functions

(define-read-only (get-stop (stop-id (string-ascii 20)))
  (map-get? transit-stops { stop-id: stop-id })
)

(define-read-only (get-vehicle (vehicle-id (string-ascii 20)))
  (map-get? transit-vehicles { vehicle-id: vehicle-id })
)

(define-read-only (get-route (route-id (string-ascii 20)))
  (map-get? transit-routes { route-id: route-id })
)

(define-read-only (get-last-update)
  (var-get last-update)
)

;; Public functions - restricted to contract owner

(define-public (add-stop 
  (stop-id (string-ascii 20)) 
  (name (string-ascii 100)) 
  (latitude int) 
  (longitude int))
  
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set transit-stops
      { stop-id: stop-id }
      {
        name: name,
        latitude: latitude,
        longitude: longitude,
        active: true
      }
    )
    (ok true)
  )
)

(define-public (add-vehicle 
  (vehicle-id (string-ascii 20)) 
  (route-id (string-ascii 20)) 
  (latitude int) 
  (longitude int) 
  (status (string-ascii 20)))
  
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set transit-vehicles
      { vehicle-id: vehicle-id }
      {
        route-id: route-id,
        latitude: latitude,
        longitude: longitude,
        last-position-update: block-height,
        status: status
      }
    )
    (ok true)
  )
)

(define-public (add-route 
  (route-id (string-ascii 20)) 
  (name (string-ascii 100)) 
  (stops (list 20 (string-ascii 20))))
  
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set transit-routes
      { route-id: route-id }
      {
        name: name,
        stops: stops,
        active: true
      }
    )
    (ok true)
  )
)

(define-public (update-vehicle-position 
  (vehicle-id (string-ascii 20)) 
  (latitude int) 
  (longitude int))
  
  (let ((vehicle (unwrap! (get-vehicle vehicle-id) err-not-found)))
    (begin
      (asserts! (is-eq tx-sender contract-owner) err-owner-only)
      (map-set transit-vehicles
        { vehicle-id: vehicle-id }
        (merge vehicle {
          latitude: latitude,
          longitude: longitude,
          last-position-update: block-height
        })
      )
      (var-set last-update block-height)
      (ok true)
    )
  )
)

(define-public (set-stop-status 
  (stop-id (string-ascii 20)) 
  (active bool))
  
  (let ((stop (unwrap! (get-stop stop-id) err-not-found)))
    (begin
      (asserts! (is-eq tx-sender contract-owner) err-owner-only)
      (map-set transit-stops
        { stop-id: stop-id }
        (merge stop { active: active })
      )
      (ok true)
    )
  )
)

(define-public (set-route-status 
  (route-id (string-ascii 20)) 
  (active bool))
  
  (let ((route (unwrap! (get-route route-id) err-not-found)))
    (begin
      (asserts! (is-eq tx-sender contract-owner) err-owner-only)
      (map-set transit-routes
        { route-id: route-id }
        (merge route { active: active })
      )
      (ok true)
    )
  )
)
