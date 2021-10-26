// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;


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
