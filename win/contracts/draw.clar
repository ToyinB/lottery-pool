;; Lottery Pool Contract
(define-constant contract-owner tx-sender)
(define-constant ERR-OVERFLOW u4)

;; Data variables
(define-data-var lottery-id uint u0)
(define-data-var lottery-balance uint u0)
(define-data-var min-players uint u3)
(define-data-var ticket-price uint u100)
(define-data-var lottery-status bool false)
(define-data-var nonce uint u0)

;; Data maps
(define-map participants { lottery-id: uint } (list 50 principal))
(define-map player-tickets { lottery-id: uint, player: principal } uint)
(define-map lottery-winners { lottery-id: uint } { winner: principal, amount: uint })

;; Private functions
(define-private (get-random-number (max uint))
  (let (
    (current-time (unwrap-panic (get-block-info? time u0)))
    (random-seed (var-get nonce))
  )
    (var-set nonce (+ random-seed u1))
    (mod (+ current-time random-seed) max)
  )
)

(define-private (select-winner (lottery-round uint)) 
  (let (
    (participants-list (unwrap-panic (map-get? participants { lottery-id: lottery-round })))
    (winner-index (get-random-number (len participants-list)))
  )
    (ok (unwrap-panic (element-at participants-list winner-index)))
  )
)

;; Private function to safely add uint values
(define-private (safe-add (a uint) (b uint))
  (let ((sum (+ a b)))
    (asserts! (>= sum a) (err ERR-OVERFLOW))
    (ok sum)
  )
)

;; Public functions
(define-public (start-lottery)
  (begin
    (asserts! (is-eq tx-sender contract-owner) (err u1))
    (var-set lottery-status true)
    (ok true)
  )
)

(define-public (buy-ticket (number-of-tickets uint))
  (let (
    (total-cost (* number-of-tickets (var-get ticket-price)))
    (current-lottery (var-get lottery-id))
  )
    ;; Check for overflow in total cost calculation
    (asserts! (>= total-cost number-of-tickets) (err ERR-OVERFLOW))
    
    (try! (stx-transfer? total-cost tx-sender (as-contract tx-sender)))
    
    (let (
      (prev-tickets (map-get? player-tickets { lottery-id: current-lottery, player: tx-sender }))
      (current-tickets (default-to u0 prev-tickets))
    )
      ;; Check for overflow in ticket addition
      (let ((new-ticket-count (try! (safe-add current-tickets number-of-tickets))))
        (begin
          (if (is-none prev-tickets)
            (map-set participants
              { lottery-id: current-lottery }
              (unwrap! (as-max-len? 
                (append 
                  (default-to (list) (map-get? participants { lottery-id: current-lottery }))
                  tx-sender
                )
                u50
              ) (err u3)))
            true
          )
          
          (map-set player-tickets
            { lottery-id: current-lottery, player: tx-sender }
            new-ticket-count
          )
          
          ;; Safely update lottery balance
          (let ((new-balance (try! (safe-add (var-get lottery-balance) total-cost))))
            (var-set lottery-balance new-balance)
            (ok true)
          )
        )
      )
    )
  )
)

(define-public (end-lottery)
  (let (
    (current-lottery (var-get lottery-id))
    (current-balance (var-get lottery-balance))
  )
    (asserts! (is-eq tx-sender contract-owner) (err u1))
    
    (let ((winner (unwrap! (select-winner current-lottery) (err u2))))
      (try! (as-contract (stx-transfer? current-balance contract-owner winner)))
      
      (map-set lottery-winners
        { lottery-id: current-lottery }
        { winner: winner, amount: current-balance }
      )
      
      (var-set lottery-id (+ current-lottery u1))
      (var-set lottery-balance u0)
      (var-set lottery-status false)
      (ok true)
    )
  )
)

;; Read-only functions
(define-read-only (get-lottery-info)
  {
    lottery-id: (var-get lottery-id),
    balance: (var-get lottery-balance),
    status: (var-get lottery-status),
    ticket-price: (var-get ticket-price),
    min-players: (var-get min-players)
  }
)

(define-read-only (get-winner (lottery-round uint))
  (map-get? lottery-winners { lottery-id: lottery-round })
)

(define-read-only (get-player-tickets (player principal) (lottery-round uint))
  (default-to u0 (map-get? player-tickets { lottery-id: lottery-round, player: player }))
)
