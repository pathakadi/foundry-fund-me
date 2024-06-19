// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test , console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test{
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;
    function setUp() external{
       DeployFundMe deployFundMe = new DeployFundMe();
       fundMe = deployFundMe.run();
       vm.deal(USER,STARTING_BALANCE);
    }
    function testUsd() public view{
        assertEq(fundMe.MINIMUM_USD(),5e18);
    }
    function testOwnerIsMsgSender() public view{
        assertEq(fundMe.getOwner(),msg.sender);
    }
    function testPriceFeedVersionIsAccurate() public view{
        assertEq(fundMe.getVersion(),4);
    }
    function testFundFailsWithoutEnoughMoney() public{
        vm.expectRevert();
        fundMe.fund();
    }
    modifier funded(){
        vm.prank(USER);
        fundMe.fund{value : SEND_VALUE}();
        _;
    }
    function testFundUpdatesFundedDataStructure() public funded{
        assertEq(fundMe.getAddressToAmountFunded(USER),SEND_VALUE);
    }
    function testAddsFunderToArrayOfFunders() public funded{
        assertEq(fundMe.getFunder(0),USER);
    }
    function testOnlyOwnerCanWithdraw() public funded{
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }
    function testWithdrawWithASingleFunder() public funded{
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance,0);
        assertEq(endingOwnerBalance,startingOwnerBalance+startingFundMeBalance);
    }
    function testWithdrawFromMultipleFunder() public funded{
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for(uint160 i = startingFunderIndex ; i < numberOfFunders ; i++){
            hoax(address(i),STARTING_BALANCE);
            fundMe.fund{value : SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();
        // Assert
        assert(address(fundMe).balance == 0);
        assert(startingOwnerBalance+startingFundMeBalance == fundMe.getOwner().balance);
    }
}