// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";

// This is not inside the contract, so it won't take a storage slot
error FundMe__NotOwner();

/**
 * @title FundMe
 * @author polarzero
 * @notice Just a basic Fund Me contract
 */

contract FundMe {
    using PriceConverter for uint256;

    // "constant" keyword allows it to not take a storage spot + easier to read
    // constants are declared LIKE_THIS
    uint256 public constant MINIMUM_USD = 50 * 1e18;

    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;

    // owner is set only once, but declared in a different line
    // So not a "constant" but a "immutable"
    // That can be called i_likeThis
    address private immutable i_owner;

    AggregatorV3Interface private s_priceFeed;

    // Can use a modifier to modify any function
    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not owner!");
        // More gas efficient
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        // Do what is under the "_" BEFORE the function that has "onlyOwner" in the declaration
        _;
        // Do what is under the "_" AFTER the function that has "onlyOwner" in the declaration
    }

    // The constructor function gets called in the same tx as the contract creation
    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // What happens if someone sends this contract Eth without calling the "fund" function ?
    // We can use some special functions -> receive() or fallback()
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    // We need to make the function payable so it can hold Eth
    function fund() public payable {
        // If the minimum fund amount is not met, then the tx is reverted
        // So number is not set to 5
        // BUT gas is spent for anything BEFORE the require
        // BUT the gas spent AFTER require, if not met, will be returned
        // s_number = 5;
        // Set a minimum fund amount
        // This function requires the value (msg.value) to be > 1 Eth
        // require(getConversionRate(msg.value) >= minimumUsd, "Didn't send enough Eth!");
        // BUT now with the library ->
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Didn't send enough Eth!"
        );
        // msg.value is considered as the parameter for getConversionRate

        // Add the funder to the list if it went through
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    // Before calling the function, do what is in "onlyOwner", THEN call the rest of the code
    function withdraw() public onlyOwner {
        // Loop through the funders array and reset it
        // for (start index; end index; stem)
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // Reset the array
        s_funders = new address[](0);

        // Withdraw the funds
        // msg.sender is of type address
        // payable(msg.sender) is of type payable address
        // Using TRANSFER : if it exceeds 2300 gas, it fails (reverted)
        // msg.sender.transfer(address(this).balance)
        // Using SEND (if it fails, it will return a bool false)
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");
        // Using CALL (no gas limit)
        // If it returns a function, or some value, it will be saved in the variables on the left
        // GENERALY RECOMMANDED
        (
            bool callSuccess, /* bytes memory dataReturned */

        ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    // We need to minimize access/reading from storage to optimize gas
    function cheaperWithdraw() public onlyOwner {
        // We store the array in memory to avoid highly expensive storage reads
        // We can't put a mapping in memory
        address[] memory funders = s_funders;
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(address funder)
        public
        view
        returns (uint256)
    {
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}
