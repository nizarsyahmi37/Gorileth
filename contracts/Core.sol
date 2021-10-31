// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;




/**
 * @title Auction
 * 
 * @dev This handles creating auctions for sale and siring of kitties.
 */
contract Auction is Breeding {
    
    
    /**
     * @dev Only CEO can sets the reference to the sale auction — for gen0 and p2p sale.
     * 
     * @param _address - Address of sale contract.
     */
    function setSaleAuctionAddress(address _address) public onlyCEO {
        
        
        /**
         * @dev Use the address provided as the candidateContract.
         */
        SaleInterface candidateContract = SaleInterface(_address);
        
        
        /**
         * @dev Verify it is the correct contract.
         */
        require(candidateContract.isSaleAuction());
        
        
        /**
         * @dev Set address of the new contract.
         */
        saleAuction = candidateContract;
        
    }
    
    
    /**
     * @dev Only CEO can set the reference to the siring auction — for siring rights.
     * 
     * @param _address - Address of siring contract.
     */
    function setSiringAuctionAddress(address _address) public onlyCEO {
        
        
        /**
         * @dev Use the address provided as the candidateContract.
         */
        SiringInterface candidateContract = SiringInterface(_address);
        
        
        /**
         * @dev Verify it is the correct contract.
         */
        require(candidateContract.isSiringAuction());
        
        
        /**
         * @dev Set address of the new contract.
         */
        siringAuction = candidateContract;
        
    }
    
    
    /**
     * @dev Put a gorilla up for sale auction.
     */
    function createSaleAuction(uint256 _gorillaId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration) external whenNotPaused {
        
        
        /**
         * @dev Ensure that the gorilla belongs to the address and is not pregnant.
         */
        require(_owns(msg.sender, _gorillaId));
        require(!isPregnant(_gorillaId));
        
        
        /**
         * @dev Approve the gorilla for the sale auction contract.
         */
        _approve(_gorillaId, address(saleAuction));
        
        
        /**
         * @dev Create sale auction for the gorilla.
         */
        saleAuction.createAuction(_gorillaId, _startingPrice, _endingPrice, _duration, msg.sender);
        
    }
    
    
    /**
     * @dev Put a gorilla up for siring auction.
     */
    function createSiringAuction(uint256 _gorillaId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration) external whenNotPaused {
        
        
        /**
         * @dev Ensure that the gorilla belongs to the address and is ready to breed.
         */
        require(_owns(msg.sender, _gorillaId));
        require(isReadyToBreed(_gorillaId));
        
        
        /**
         * @dev Approve the gorilla for the siring auction contract.
         */
        _approve(_gorillaId, address(siringAuction));
        
        
        /**
         * @dev Create siring auction for the gorilla.
         */
        siringAuction.createAuction(_gorillaId, _startingPrice, _endingPrice, _duration, msg.sender);
        
    }
    
    
    /**
     * @dev Complete siring auction by bidding to immediately breed with sire on auction.
     * 
     * @param _sireId - ID of the sire on auction.
     * @param _matronId - ID of the matron owned by the bidder.
     */
    function bidOnSiringAuction(uint256 _sireId, uint256 _matronId) external payable whenNotPaused {
        
        
        /**
         * @dev Check that the address own the gorilla, ensure that it is ready to breed and can breed with the sire.
         */
        require(_owns(msg.sender, _matronId));
        require(isReadyToBreed(_matronId));
        require(_canBreedWithViaAuction(_matronId, _sireId));
        
        
        /**
         * @dev Define the current price of the auction for the gorilla.
         */
        uint256 currentPrice = siringAuction.getCurrentPrice(_sireId);
        
        
        /**
         * @dev Check whether the bid is higher than the total of current price for the gorilla inclusive of birth fee.
         */
        require(msg.value >= currentPrice + autoBirthFee);
        
        
        /**
         * @dev Accept bid for the sire and initiate breeding with the matron.
         */
        siringAuction.bid{value : msg.value - autoBirthFee}(_sireId);
        _breedWith(uint32(_matronId), uint32(_sireId));
        
    }
    
    
    /**
     * @dev Only CLevel can transfers the balance of the auction contracts to the Core contract.
     */
    function withdrawAuctionBalances() external onlyCLevel {
        
        /**
         * @dev Withdraw the balance from sale auction.
         */
        saleAuction.withdrawBalance();
        
        
        /**
         * @dev Withdraw the balance from siring auction.
         */
        siringAuction.withdrawBalance();
        
    }
    
}


/**
 * @title Minting
 * 
 * @dev This has all the functions related to creating a gorilla.
 */
contract Minting is Auction {
    
    
    /**
     * @dev The limits for contract owner to create gorillas.
     */
    uint256 public constant promoLimit = 5000;
    uint256 public constant gen0Limit = 45000;
    
    
    /**
     * @dev Default values for gen0 auctions.
     */
    uint256 public constant gen0StartingPrice = 25 ether;
    uint256 public constant get0AuctionDuration = 1 days;
    
    
    /**
     * @dev Counts the number of gorillas created by contract owner.
     */
    uint256 public promoCreatedCount;
    uint256 public gen0CreatedCount;
    
    
    /**
     * @dev This creates promo gorillas.
     * 
     * @param _genes the encoded genes of the kitten to be created, any value is accepted
     * @param _owner the future owner of the created kittens. Default to contract COO
     * 
     * Requirement:
     * - Promo gorillas created must not exceed the limit. 
     * - Can only be called by the current COO.
     */
    function createPromoGorillas(uint256 _genes, address _owner) external onlyCOO {
        
        
        /**
         * @dev Take the address provided as the owner for the gorilla.
         */
        address gorillaOwner = _owner;
        
        
        /**
         * @dev This ensure the owner for the gorilla will be assigned to the current COO address if the owner is address(0).
         */
        if (gorillaOwner == address(0)) {
             gorillaOwner = cooAddress;
        }
        
        
        /**
         * @dev Ensure that total promo gorilla does not exceed the limit.
         */
        require(promoCreatedCount < promoLimit);
        
        
        /**
         * @dev Increase the count for promo gorilla and create the gorilla.
         */
        promoCreatedCount++;
        _createGorilla(0, 0, 0, _genes, gorillaOwner);
        
    }
    
    
    /**
     * @dev Create a new gen0 gorilla using the genes provided and auction it.
     */
    function createGen0Auction(uint256 _genes) external onlyCOO {
        
        
        /**
         * @dev Ensure that total gen0 gorilla does not exceed the limit.
         */
        require(gen0CreatedCount < gen0Limit);
        
        
        /**
         * @dev This create the new gen0 gorilla and approve it for auction.
         */
        uint256 gorillaId = _createGorilla(0, 0, 0, _genes, address(this));
        _approve(gorillaId, address(saleAuction));
        
        
        /**
         * @dev This create the auction for this new gen0 gorilla.
         */
        saleAuction.createAuction(gorillaId, _computeNextGen0Price(), 0, get0AuctionDuration, address(this));
        
        
        /**
         * @dev This will increase the number of gen0 created.
         */
        gen0CreatedCount++;
    }
    
    
    /**
     * @dev This compute the next starting price.
     */
    function _computeNextGen0Price() internal view returns (uint256) {
        
        
        /**
         * @dev This set the average price for gen0 auction based on the average from the past gen0 prices.
         */
        uint256 avePrice = saleAuction.averageGen0SalePrice();
        
        
        /**
         * @dev Ensure that the average price does not overflow.
         */
        require(avePrice == uint256(uint128(avePrice)));
        
        
        /**
         * @dev This set the next price for gen0 auction to be 150% of the average price.
         */
        uint256 nextPrice = (avePrice * 3 / 2);
        
        
        /**
         * @dev Ensure that auction price will not be lower than the default starting price.
         */
        if (nextPrice < gen0StartingPrice) {
            nextPrice = gen0StartingPrice;
        }
        return nextPrice;
        
    }
    
}


/**
 * @title Core
 * 
 * @dev This is the main contract for Gorileth.
 */
contract Core is Minting {
    
    
    /**
     * @dev This will be set if the core contract is broken or when upgrade is required.
     */
    address public newContractAddress;
    
    
    
    /**
     * @dev This creates main instance for this contract.
     */
    constructor() {
        
        
        /**
         * @dev This contract will be initialized in paused state.
         */
        paused = true;
        
        
        /**
         * @dev This set the creator as the initial CEO.
         */
        ceoAddress = msg.sender;
        
        
        /**
         * @dev This set the creator as the initial COO.
         */
        cooAddress = msg.sender;
        
        
        /**
         * @dev This contract will be initialized with the creation of a mythical gorilla known as Zeroth.
         */
        _createGorilla(0 , 0 , 0 , type(uint256).max , address(0));
        
    }
    
    
    /** 
     * @dev This ensure that only the two whitelisted auction contract are allowed to send funds to this contract.
     */
    receive() external payable {
        require(msg.sender == address(saleAuction) || msg.sender == address(siringAuction) , "You cannot send funds here.");
    }
    
    
    /**
     * @dev This returns all the relevant information about a specific gorilla.
     * 
     * @param _id The ID of the gorilla.
     */
    function getGorilla(uint256 _id) external view returns (bool isGestating , bool isReady , uint256 cooldownIndex , uint256 nextActionAt , uint256 siringWithId , uint256 birthTime , uint256 matronId , uint256 sireId , uint256 gen , uint256 genes) {
        
        
        /**
         * @dev This gets the gorilla with the given ID from storage.
         */
        Gorilla storage gor = gorillas[_id];
        
        isGestating = (gor.siringWithId != 0);
        isReady = (gor.cooldownEndBlock <= block.number);
        cooldownIndex = uint256(gor.cooldownIndex);
        nextActionAt = uint256(gor.cooldownEndBlock);
        siringWithId = uint256(gor.siringWithId);
        birthTime = uint256(gor.birthTime);
        matronId = uint256(gor.matronId);
        sireId = uint256(gor.sireId);
        gen = uint256(gor.gen);
        genes = gor.genes;
        
    }
    

    /**
     * @dev Ensure all external contract addresses except newContractAddress have been set before contract can be unpaused.
     */
    function unpause() public onlyCEO whenPaused override {
        require(address(saleAuction) != address(0));
        require(address(siringAuction) != address(0));
        require(address(geneScience) != address(0));
        require(newContractAddress == address(0));

        /**
         * @dev This actually unpause the contract.
         */
        super.unpause();
        
    }
    
    
    /**
     * @dev This captures the balance available to this contract.
     * 
     * Requirement:
     * - Can only be called by the current CFO.
     */
    function withdrawBalance() external onlyCFO {
        
        
        /**
         * @dev This is the balance available to this contract.
         */
        uint256 balance = address(this).balance;
        
        
        /**
         * @dev This is the fees to be subtracted for pregnant gorillas, plus 1 of margin.
         */
        uint256 subtractFees = (pregnantGorillas + 1) * autoBirthFee;
        
        
        /**
         * @dev This ensure that the function is callable only when the balance is more than the fees.
         */
        if (balance > subtractFees) {
            payable(cfoAddress).transfer(balance - subtractFees);
        }
    }
    
}
