pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "forge-std/Script.sol";
import "src/testERC20.sol";
import "src/UniswapV2Factory.sol";
import "src/router.sol";
import "src/interfaces/IUniswapV2Pair.sol";
import "script/csvWriter.s.sol";

contract SetUp is Test, CSVWriter {
    TestERC20 testToken1;
    TestERC20 testToken2;
    UniswapV2Factory factory;
    Router router;

    uint STARTING_BALANCE = 10000000000000000000 ether;

    address tester = address(0x1234);

    function setUp() public virtual {
        vm.startPrank(tester);
        testToken1 = new TestERC20("test1", "T1", 18, STARTING_BALANCE);
        testToken2 = new TestERC20("test2", "T2", 18, STARTING_BALANCE);
        factory = new UniswapV2Factory(msg.sender);
        router = new Router(address(factory));
        vm.stopPrank();
    }
}

contract RouterTest is SetUp {
    function addLiquidity(
        address swapper,
        address tokenA,
        address tokenB,
        uint amtA,
        uint amtB,
        uint slippageRatio
    ) internal returns (uint) {
        vm.startPrank(swapper);
        testToken1.approve(address(router), STARTING_BALANCE);
        testToken2.approve(address(router), STARTING_BALANCE);
        uint liquidity = router.addLiquidity(
            address(tokenA),
            address(tokenB),
            amtA,
            amtB,
            slippageRatio
        );
        vm.stopPrank();
        return liquidity;
    }

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
        uint expectedLiquidity = addLiquidity(
            tester,
            address(testToken1),
            address(testToken2),
            10000000000 ether,
            10000000000 ether,
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
        uint expectedLiquidity1 = addLiquidity(
            tester,
            address(testToken1),
            address(testToken2),
            10 ether,
            10 ether,
            10 ether
        );
        uint expectedLiquidity2 = addLiquidity(
            tester,
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
        vm.assume(amountA <= 1000000000000000000 ether && amountA > 0);
        vm.assume(amountB <= 1000000000000000000 ether && amountB > 0);
        allowedRatio = allowedRatio % 1 ether;
        bool writeValues = false;

        //data to print
        string[] memory allCSVData = new string[](4);
        allCSVData[1] = convertUintToString(amountA);
        allCSVData[2] = convertUintToString(amountB);
        allCSVData[3] = convertUintToString(allowedRatio);

        //add initial liquidity into pool 1:1
        testAddLiquidity();
        uint currentRatio = (amountA * 1e18) / amountB;
        uint minRatio = allowedRatio > 1 ether ? 0 : 1 ether - allowedRatio;
        vm.startPrank(tester);
        if (currentRatio > 1 ether + allowedRatio || currentRatio < minRatio) {
            if (writeValues) {
                allCSVData[0] = "fail";
                writeToCSV(
                    "testFiles/test.txt",
                    convertArrayOfStringsToCSVLine(allCSVData)
                );
            }
            vm.expectRevert();
            router.addLiquidity(
                address(testToken1),
                address(testToken2),
                amountA,
                amountB,
                allowedRatio
            );
        } else {
            if (writeValues) {
                allCSVData[0] = "success";
                writeToCSV(
                    "testFiles/test.txt",
                    convertArrayOfStringsToCSVLine(allCSVData)
                );
            }
            router.addLiquidity(
                address(testToken1),
                address(testToken2),
                amountA,
                amountB,
                allowedRatio
            );
        }
    }

    function testRemoveLiquidity() public {
        testAddLiquidity();
        vm.startPrank(tester);
        IUniswapV2Pair pair = IUniswapV2Pair(
            factory.getPair(address(testToken1), address(testToken2))
        );
        pair.approve(address(router), STARTING_BALANCE);
        uint balanceOfLP = pair.balanceOf(tester);
        router.removeLiquidity(
            address(testToken1),
            address(testToken2),
            balanceOfLP,
            0,
            0
        );
        assertEq(pair.balanceOf(tester), 0);
        assert(testToken1.balanceOf(address(pair)) > 0);
        assert(testToken2.balanceOf(address(pair)) > 0);
        //shouln't be able to do this again
        vm.expectRevert();
        router.removeLiquidity(
            address(testToken1),
            address(testToken2),
            balanceOfLP,
            0,
            0
        );
    }

    function testSingleSwap() public {
        addLiquidity(
            tester,
            address(testToken1),
            address(testToken2),
            10000 ether,
            10000 ether,
            10 ether
        );
        vm.startPrank(tester);
        router.swap(address(testToken1), address(testToken2), 10 ether, 0);
    }
}
