pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "forge-std/Script.sol";
import "src/testERC20.sol";
import "src/UniswapV2Factory.sol";
import "src/router.sol";
import "src/interfaces/IUniswapV2Pair.sol";

contract SetUp is Test {
    TestERC20 testToken1;
    TestERC20 testToken2;
    UniswapV2Factory factory;
    Router router;

    address tester = address(0x1234);

    function setUp() public virtual {
        vm.startPrank(tester);
        testToken1 = new TestERC20("test1", "T1", 18);
        testToken2 = new TestERC20("test2", "T2", 18);
        factory = new UniswapV2Factory(msg.sender);
        router = new Router(address(factory));
        vm.stopPrank();
    }
}

contract RouterTest is SetUp {
    uint failedTests;
    uint success;

    function testNeedAllowance() public {
        vm.startPrank(tester);
        //will revert since no allowance was set
        vm.expectRevert();
        router.addLiquidity(
            address(testToken1),
            address(testToken2),
            50 ether,
            50 ether,
            10
        );
        vm.stopPrank();
    }

    function testAddLiquidity() public {
        vm.startPrank(tester);
        testToken1.approve(address(router), 1000 ether);
        testToken2.approve(address(router), 1000 ether);
        uint expectedLiquidity = router.addLiquidity(
            address(testToken1),
            address(testToken2),
            10 ether,
            10 ether,
            10 ether
        );

        address pair = factory.getPair(
            address(testToken1),
            address(testToken2)
        );
        vm.stopPrank();
        assert(pair != address(0));
        assertEq(IUniswapV2Pair(pair).balanceOf(tester), expectedLiquidity);
    }

    function testMultipleAddLiquidity() public {
        vm.startPrank(tester);
        testToken1.approve(address(router), 1000 ether);
        testToken2.approve(address(router), 1000 ether);
        uint expectedLiquidity1 = router.addLiquidity(
            address(testToken1),
            address(testToken2),
            10 ether,
            10 ether,
            10 ether
        );
        uint expectedLiquidity2 = router.addLiquidity(
            address(testToken1),
            address(testToken2),
            10 ether,
            10 ether,
            10 ether
        );
        vm.stopPrank();
        address pair = factory.getPair(
            address(testToken1),
            address(testToken2)
        );
        assertEq(
            IUniswapV2Pair(pair).balanceOf(tester),
            expectedLiquidity1 + expectedLiquidity2
        );
    }

    function testAddLiquidityWithWrongRatio() public {
        //add initial liquidity into pool
        testAddLiquidity();
        //pool ratio is 1:1, we will try 2:1
        vm.expectRevert();
        vm.startPrank(tester);
        router.addLiquidity(
            address(testToken1),
            address(testToken2),
            20 ether,
            10 ether,
            0.1 ether
        );
    }

    function testFuzzLiquidityAmounts(
        uint amountA,
        uint amountB,
        uint allowedRatio
    ) public {
        vm.assume(amountA <= 990 ether && amountA > 0);
        vm.assume(amountB <= 990 ether && amountB > 0);
        vm.assume(allowedRatio <= 1 ether);
        //add initial liquidity into pool 1:1
        testAddLiquidity();
        uint currentRatio = (amountA * 1e18) / amountB;
        uint minRatio = allowedRatio > 1 ether ? 0 : 1 ether - allowedRatio;
        vm.startPrank(tester);
        if (currentRatio > 1 ether + allowedRatio || currentRatio < minRatio) {
            vm.expectRevert();
            router.addLiquidity(
                address(testToken1),
                address(testToken2),
                amountA,
                amountB,
                allowedRatio
            );
            failedTests++;
        } else {
            router.addLiquidity(
                address(testToken1),
                address(testToken2),
                amountA,
                amountB,
                allowedRatio
            );
            success++;
        }
        console2.log("test");
    }

    function printFails() internal {
        console.log("success: ", success);
        console.log("failed: ", failedTests);
    }
}
