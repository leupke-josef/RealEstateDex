
;; title: RealEstateDex
;; version: 1.0.0
;; summary: Synthetic REIT exposure platform for decentralized real estate investment
;; description: A smart contract that allows users to mint and trade synthetic REIT tokens backed by STX collateral

;; traits
;; SIP-010 trait implementation will be added when deployed to mainnet
;; (impl-trait 'SP3FBR2AGK5H9QBDH3EEN6DF8EK8JY7RX8QJ5SVTE.sip-010-trait-ft-standard.sip-010-trait)

;; token definitions
(define-fungible-token synthetic-reit)

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_OWNER_ONLY (err u100))
(define-constant ERR_NOT_TOKEN_OWNER (err u101))
(define-constant ERR_INSUFFICIENT_BALANCE (err u102))
(define-constant ERR_INVALID_AMOUNT (err u103))
(define-constant ERR_INVALID_PRINCIPAL (err u104))
(define-constant ERR_COLLATERAL_RATIO (err u105))
(define-constant ERR_ORACLE_OFFLINE (err u106))
(define-constant ERR_LIQUIDATION_THRESHOLD (err u107))

;; Minimum collateral ratio (150%)
(define-constant MIN_COLLATERAL_RATIO u150)
;; Liquidation threshold (120%)
(define-constant LIQUIDATION_THRESHOLD u120)
;; Precision for calculations
(define-constant PRECISION u1000000)

;; data vars
(define-data-var contract-owner principal CONTRACT_OWNER)
(define-data-var total-supply uint u0)
(define-data-var reit-price uint u100000000) ;; Price in micro-STX (1 REIT = 100 STX initially)
(define-data-var oracle-enabled bool true)
(define-data-var minting-enabled bool true)

;; data maps
;; User balances and collateral
(define-map balances principal uint)
(define-map collateral-balances principal uint)
(define-map user-positions 
  principal 
  {
    collateral: uint,
    debt: uint,
    last-interaction: uint
  }
)

;; Price history for oracles
(define-map price-history uint uint)
(define-map authorized-oracles principal bool)

;; Token name and symbol
(define-read-only (get-name)
  (ok "Synthetic REIT Token")
)

(define-read-only (get-symbol)
  (ok "sREIT")
)

(define-read-only (get-decimals)
  (ok u6)
)

;; public functions

;; SIP-010 Standard Functions
(define-public (transfer (amount uint) (from principal) (to principal) (memo (optional (buff 34))))
  (begin
    (asserts! (or (is-eq from tx-sender) (is-eq from contract-caller)) ERR_NOT_TOKEN_OWNER)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (match (ft-transfer? synthetic-reit amount from to)
      response (begin
        (print memo)
        (ok true)
      )
      error (err error)
    )
  )
)

(define-read-only (get-balance (who principal))
  (ok (ft-get-balance synthetic-reit who))
)

(define-read-only (get-total-supply)
  (ok (ft-get-supply synthetic-reit))
)

(define-read-only (get-token-uri)
  (ok none)
)

;; Core Platform Functions

;; Deposit STX as collateral
(define-public (deposit-collateral (amount uint))
  (let 
    (
      (caller tx-sender)
      (current-collateral (default-to u0 (map-get? collateral-balances caller)))
    )
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (var-get minting-enabled) ERR_LIQUIDATION_THRESHOLD)
    
    ;; Transfer STX from user to contract
    (try! (stx-transfer? amount caller (as-contract tx-sender)))
    
    ;; Update collateral balance
    (map-set collateral-balances caller (+ current-collateral amount))
    
    ;; Update user position
    (match (map-get? user-positions caller)
      position 
      (map-set user-positions caller 
        (merge position {
          collateral: (+ (get collateral position) amount),
          last-interaction: block-height
        })
      )
      (map-set user-positions caller {
        collateral: amount,
        debt: u0,
        last-interaction: block-height
      })
    )
    
    (print {action: "deposit-collateral", user: caller, amount: amount})
    (ok amount)
  )
)

;; Mint synthetic REIT tokens against collateral
(define-public (mint-sreit (amount uint))
  (let
    (
      (caller tx-sender)
      (reit-price-current (var-get reit-price))
      (collateral-needed (* (* amount reit-price-current) MIN_COLLATERAL_RATIO))
      (collateral-needed-adjusted (/ collateral-needed (* PRECISION u100)))
      (user-collateral (default-to u0 (map-get? collateral-balances caller)))
      (current-debt (match (map-get? user-positions caller)
        position (get debt position)
        u0
      ))
      (total-debt-value (* (+ current-debt amount) reit-price-current))
      (total-debt-adjusted (/ total-debt-value PRECISION))
    )
    
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (var-get minting-enabled) ERR_LIQUIDATION_THRESHOLD)
    (asserts! (var-get oracle-enabled) ERR_ORACLE_OFFLINE)
    
    ;; Check collateralization ratio
    (asserts! (>= user-collateral total-debt-adjusted) ERR_COLLATERAL_RATIO)
    (asserts! (>= (* user-collateral u100) (* total-debt-adjusted MIN_COLLATERAL_RATIO)) ERR_COLLATERAL_RATIO)
    
    ;; Mint tokens
    (try! (ft-mint? synthetic-reit amount caller))
    
    ;; Update user position
    (match (map-get? user-positions caller)
      position
      (map-set user-positions caller
        (merge position {
          debt: (+ (get debt position) amount),
          last-interaction: block-height
        })
      )
      (map-set user-positions caller {
        collateral: user-collateral,
        debt: amount,
        last-interaction: block-height
      })
    )
    
    ;; Update total supply
    (var-set total-supply (+ (var-get total-supply) amount))
    
    (print {action: "mint-sreit", user: caller, amount: amount, price: reit-price-current})
    (ok amount)
  )
)

;; Burn synthetic REIT tokens to reduce debt
(define-public (burn-sreit (amount uint))
  (let
    (
      (caller tx-sender)
      (user-balance (ft-get-balance synthetic-reit caller))
      (user-position (unwrap! (map-get? user-positions caller) ERR_INVALID_PRINCIPAL))
      (current-debt (get debt user-position))
      (burn-amount (if (> amount current-debt) current-debt amount))
    )
    
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (>= user-balance amount) ERR_INSUFFICIENT_BALANCE)
    (asserts! (> current-debt u0) ERR_INSUFFICIENT_BALANCE)
    
    ;; Burn tokens
    (try! (ft-burn? synthetic-reit burn-amount caller))
    
    ;; Update user position
    (map-set user-positions caller
      (merge user-position {
        debt: (- current-debt burn-amount),
        last-interaction: block-height
      })
    )
    
    ;; Update total supply
    (var-set total-supply (- (var-get total-supply) burn-amount))
    
    (print {action: "burn-sreit", user: caller, amount: burn-amount})
    (ok burn-amount)
  )
)

;; Withdraw collateral (only if sufficiently collateralized)
(define-public (withdraw-collateral (amount uint))
  (let
    (
      (caller tx-sender)
      (user-collateral (default-to u0 (map-get? collateral-balances caller)))
      (user-position (unwrap! (map-get? user-positions caller) ERR_INVALID_PRINCIPAL))
      (user-debt (get debt user-position))
      (remaining-collateral (- user-collateral amount))
      (reit-price-current (var-get reit-price))
      (debt-value (* user-debt reit-price-current))
      (debt-value-adjusted (/ debt-value PRECISION))
      (required-collateral (* debt-value-adjusted MIN_COLLATERAL_RATIO))
      (required-collateral-adjusted (/ required-collateral u100))
    )
    
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (>= user-collateral amount) ERR_INSUFFICIENT_BALANCE)
    
    ;; If user has debt, check collateralization
    (if (> user-debt u0)
      (asserts! (>= remaining-collateral required-collateral-adjusted) ERR_COLLATERAL_RATIO)
      true
    )
    
    ;; Transfer STX back to user
    (try! (as-contract (stx-transfer? amount tx-sender caller)))
    
    ;; Update collateral balance
    (map-set collateral-balances caller remaining-collateral)
    
    ;; Update user position
    (map-set user-positions caller
      (merge user-position {
        collateral: remaining-collateral,
        last-interaction: block-height
      })
    )
    
    (print {action: "withdraw-collateral", user: caller, amount: amount})
    (ok amount)
  )
)

;; Admin Functions

;; Update REIT price (oracle function)
(define-public (update-reit-price (new-price uint))
  (begin
    (asserts! (default-to false (map-get? authorized-oracles tx-sender)) ERR_OWNER_ONLY)
    (asserts! (> new-price u0) ERR_INVALID_AMOUNT)
    
    ;; Store price history
    (map-set price-history block-height new-price)
    (var-set reit-price new-price)
    
    (print {action: "price-update", new-price: new-price, block: block-height})
    (ok new-price)
  )
)

;; Add authorized oracle
(define-public (add-oracle (oracle principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_OWNER_ONLY)
    (map-set authorized-oracles oracle true)
    (ok true)
  )
)

;; Remove authorized oracle
(define-public (remove-oracle (oracle principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_OWNER_ONLY)
    (map-delete authorized-oracles oracle)
    (ok true)
  )
)

;; Toggle minting
(define-public (toggle-minting)
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_OWNER_ONLY)
    (var-set minting-enabled (not (var-get minting-enabled)))
    (ok (var-get minting-enabled))
  )
)

;; Toggle oracle
(define-public (toggle-oracle)
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_OWNER_ONLY)
    (var-set oracle-enabled (not (var-get oracle-enabled)))
    (ok (var-get oracle-enabled))
  )
)

;; read only functions

;; Get user's collateral balance
(define-read-only (get-collateral-balance (user principal))
  (default-to u0 (map-get? collateral-balances user))
)

;; Get user's position details
(define-read-only (get-user-position (user principal))
  (map-get? user-positions user)
)

;; Get current REIT price
(define-read-only (get-reit-price)
  (var-get reit-price)
)

;; Get collateralization ratio for a user
(define-read-only (get-collateral-ratio (user principal))
  (match (map-get? user-positions user)
    position
    (let
      (
        (collateral (get collateral position))
        (debt (get debt position))
        (reit-price-current (var-get reit-price))
      )
      (if (is-eq debt u0)
        (some u0) ;; No debt = infinite ratio
        (let
          (
            (debt-value (* debt reit-price-current))
            (debt-value-adjusted (/ debt-value PRECISION))
          )
          (if (is-eq debt-value-adjusted u0)
            (some u0)
            (some (/ (* collateral u100) debt-value-adjusted))
          )
        )
      )
    )
    none
  )
)

;; Check if position can be liquidated
(define-read-only (can-liquidate (user principal))
  (match (get-collateral-ratio user)
    ratio (< ratio LIQUIDATION_THRESHOLD)
    false
  )
)

;; Get price at specific block
(define-read-only (get-price-at-block (block uint))
  (map-get? price-history block)
)

;; Check if address is authorized oracle
(define-read-only (is-authorized-oracle (oracle principal))
  (default-to false (map-get? authorized-oracles oracle))
)

;; Get contract status
(define-read-only (get-contract-status)
  {
    minting-enabled: (var-get minting-enabled),
    oracle-enabled: (var-get oracle-enabled),
    current-price: (var-get reit-price),
    total-supply: (var-get total-supply),
    contract-owner: (var-get contract-owner)
  }
)

;; private functions

;; Initialize contract with owner as authorized oracle
(begin
  (map-set authorized-oracles CONTRACT_OWNER true)
)
