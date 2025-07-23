(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-invalid-params (err u104))

(define-data-var next-plant-id uint u1)
(define-data-var next-swap-id uint u1)
(define-data-var next-contest-id uint u1)

(define-map plants
  uint
  {
    owner: principal,
    name: (string-ascii 50),
    species: (string-ascii 50),
    rarity: uint,
    lat: int,
    lng: int,
    care-instructions: (string-ascii 200),
    growth-stage: uint,
    birth-block: uint,
    reputation: uint
  }
)

(define-map plant-owners
  principal
  (list 100 uint)
)

(define-map swap-listings
  uint
  {
    plant-id: uint,
    owner: principal,
    desired-species: (string-ascii 50),
    lat: int,
    lng: int,
    active: bool,
    created-block: uint
  }
)

(define-map user-reputation
  principal
  uint
)

(define-map contests
  uint
  {
    name: (string-ascii 50),
    description: (string-ascii 200),
    end-block: uint,
    reward-amount: uint,
    winner: (optional principal),
    active: bool
  }
)

(define-map contest-entries
  {contest-id: uint, participant: principal}
  {plant-id: uint, votes: uint}
)

(define-map contest-votes
  {contest-id: uint, voter: principal, plant-id: uint}
  bool
)

(define-public (mint-plant 
  (name (string-ascii 50))
  (species (string-ascii 50))
  (rarity uint)
  (lat int)
  (lng int)
  (care-instructions (string-ascii 200))
)
  (let ((plant-id (var-get next-plant-id)))
    (map-set plants plant-id {
      owner: tx-sender,
      name: name,
      species: species,
      rarity: rarity,
      lat: lat,
      lng: lng,
      care-instructions: care-instructions,
      growth-stage: u1,
      birth-block: stacks-block-height,
      reputation: u0
    })
    (map-set plant-owners tx-sender 
      (unwrap-panic (as-max-len? 
        (append (default-to (list) (map-get? plant-owners tx-sender)) plant-id)
        u100
      ))
    )
    (var-set next-plant-id (+ plant-id u1))
    (update-user-reputation tx-sender (* rarity u10))
    (ok plant-id)
  )
)

(define-public (create-swap-listing
  (plant-id uint)
  (desired-species (string-ascii 50))
  (lat int)
  (lng int)
)
  (let ((plant (unwrap! (map-get? plants plant-id) err-not-found))
        (swap-id (var-get next-swap-id)))
    (asserts! (is-eq (get owner plant) tx-sender) err-unauthorized)
    (map-set swap-listings swap-id {
      plant-id: plant-id,
      owner: tx-sender,
      desired-species: desired-species,
      lat: lat,
      lng: lng,
      active: true,
      created-block: stacks-block-height
    })
    (var-set next-swap-id (+ swap-id u1))
    (ok swap-id)
  )
)

(define-public (execute-swap
  (swap-id uint)
  (offered-plant-id uint)
)
  (let ((swap (unwrap! (map-get? swap-listings swap-id) err-not-found))
        (offered-plant (unwrap! (map-get? plants offered-plant-id) err-not-found))
        (requested-plant (unwrap! (map-get? plants (get plant-id swap)) err-not-found)))
    (asserts! (get active swap) err-not-found)
    (asserts! (is-eq (get owner offered-plant) tx-sender) err-unauthorized)
    (asserts! (is-eq (get species offered-plant) (get desired-species swap)) err-invalid-params)
    
    (try! (transfer-plant (get plant-id swap) (get owner swap) tx-sender))
    (try! (transfer-plant offered-plant-id tx-sender (get owner swap)))
    
    (map-set swap-listings swap-id (merge swap {active: false}))
    (update-user-reputation tx-sender u50)
    (update-user-reputation (get owner swap) u50)
    (ok true)
  )
)

(define-public (update-growth-stage
  (plant-id uint)
  (new-stage uint)
)
  (let ((plant (unwrap! (map-get? plants plant-id) err-not-found)))
    (asserts! (is-eq (get owner plant) tx-sender) err-unauthorized)
    (asserts! (> new-stage (get growth-stage plant)) err-invalid-params)
    (map-set plants plant-id (merge plant {growth-stage: new-stage}))
    (update-user-reputation tx-sender (* new-stage u25))
    (ok true)
  )
)

(define-public (rate-plant
  (plant-id uint)
  (rating uint)
)
  (let ((plant (unwrap! (map-get? plants plant-id) err-not-found)))
    (asserts! (not (is-eq (get owner plant) tx-sender)) err-unauthorized)
    (asserts! (and (>= rating u1) (<= rating u5)) err-invalid-params)
    (map-set plants plant-id 
      (merge plant {reputation: (+ (get reputation plant) rating)})
    )
    (update-user-reputation (get owner plant) (* rating u10))
    (ok true)
  )
)

(define-public (create-contest
  (name (string-ascii 50))
  (description (string-ascii 200))
  (duration-blocks uint)
  (reward-amount uint)
)
  (let ((contest-id (var-get next-contest-id)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set contests contest-id {
      name: name,
      description: description,
      end-block: (+ stacks-block-height duration-blocks),
      reward-amount: reward-amount,
      winner: none,
      active: true
    })
    (var-set next-contest-id (+ contest-id u1))
    (ok contest-id)
  )
)

(define-public (enter-contest
  (contest-id uint)
  (plant-id uint)
)
  (let ((contest (unwrap! (map-get? contests contest-id) err-not-found))
        (plant (unwrap! (map-get? plants plant-id) err-not-found)))
    (asserts! (get active contest) err-not-found)
    (asserts! (< stacks-block-height (get end-block contest)) err-invalid-params)
    (asserts! (is-eq (get owner plant) tx-sender) err-unauthorized)
    (map-set contest-entries {contest-id: contest-id, participant: tx-sender}
      {plant-id: plant-id, votes: u0}
    )
    (ok true)
  )
)

(define-public (vote-contest
  (contest-id uint)
  (plant-id uint)
  (participant principal)
)
  (let ((contest (unwrap! (map-get? contests contest-id) err-not-found))
        (entry (unwrap! (map-get? contest-entries {contest-id: contest-id, participant: participant}) err-not-found)))
    (asserts! (get active contest) err-not-found)
    (asserts! (< stacks-block-height (get end-block contest)) err-invalid-params)
    (asserts! (is-none (map-get? contest-votes {contest-id: contest-id, voter: tx-sender, plant-id: plant-id})) err-already-exists)
    (map-set contest-votes {contest-id: contest-id, voter: tx-sender, plant-id: plant-id} true)
    (map-set contest-entries {contest-id: contest-id, participant: participant}
      (merge entry {votes: (+ (get votes entry) u1)})
    )
    (ok true)
  )
)

(define-public (finalize-contest
  (contest-id uint)
  (winner principal)
)
  (let ((contest (unwrap! (map-get? contests contest-id) err-not-found)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (get active contest) err-not-found)
    (asserts! (>= stacks-block-height (get end-block contest)) err-invalid-params)
    (map-set contests contest-id 
      (merge contest {winner: (some winner), active: false})
    )
    (update-user-reputation winner (get reward-amount contest))
    (ok true)
  )
)

(define-private (transfer-plant (plant-id uint) (from principal) (to principal))
  (let ((plant (unwrap! (map-get? plants plant-id) err-not-found)))
    (asserts! (is-eq (get owner plant) from) err-unauthorized)
    (map-set plants plant-id (merge plant {owner: to}))
    (ok true)
  )
)

(define-private (update-user-reputation
  (user principal)
  (points uint)
)
  (map-set user-reputation user
    (+ (default-to u0 (map-get? user-reputation user)) points)
  )
)

(define-read-only (get-plant (plant-id uint))
  (map-get? plants plant-id)
)

(define-read-only (get-user-plants (user principal))
  (map-get? plant-owners user)
)

(define-read-only (get-swap-listing (swap-id uint))
  (map-get? swap-listings swap-id)
)

(define-read-only (get-user-reputation (user principal))
  (default-to u0 (map-get? user-reputation user))
)

(define-read-only (get-contest (contest-id uint))
  (map-get? contests contest-id)
)

(define-read-only (get-contest-entry (contest-id uint) (participant principal))
  (map-get? contest-entries {contest-id: contest-id, participant: participant})
)

(define-read-only (get-next-plant-id)
  (var-get next-plant-id)
)

(define-read-only (get-next-swap-id)
  (var-get next-swap-id)
)

(define-read-only (get-next-contest-id)
  (var-get next-contest-id)
)
