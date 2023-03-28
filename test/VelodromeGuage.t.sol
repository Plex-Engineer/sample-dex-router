pragma solidity ^0.8.18;

import "./Router.t.sol";
import "src/velodrome/Velo.sol";
import "src/velodrome/VeArtProxy.sol";
import {VotingEscrow} from "src/velodrome/VotingEscrow.sol";
import {GaugeFactory} from "src/velodrome/factories/GaugeFactory.sol";
import {BribeFactory} from "src/velodrome/factories/BribeFactory.sol";
import {Voter} from "src/velodrome/Voter.sol";

contract VelodromeGuageTest is SetUp {
    Velo veloToken;
    VotingEscrow veNFT;
    Voter voter;

    modifier startWithLiquidity() {
        addLiquidity(
            tester,
            address(testToken1),
            address(testToken2),
            INITIAL_LIQUIDITY,
            INITIAL_LIQUIDITY,
            100 ether,
            true
        );
        _;
    }

    function addLiquidity(
        address swapper,
        address tokenA,
        address tokenB,
        uint amtA,
        uint amtB,
        uint slippageRatio,
        bool stable
    ) internal returns (uint) {
        vm.startPrank(swapper);
        testToken1.approve(address(router), STARTING_BALANCE);
        testToken2.approve(address(router), STARTING_BALANCE);
        uint liquidity = router.velodromeAddLiquidity(
            address(tokenA),
            address(tokenB),
            amtA,
            amtB,
            slippageRatio,
            stable
        );
        vm.stopPrank();
        return liquidity;
    }

    function setUp() public override {
        super.setUp();
        vm.startPrank(tester);
        //create factories
        GaugeFactory gaugeFactory = new GaugeFactory();
        BribeFactory bribeFactory = new BribeFactory();
        //create token for rewards
        veloToken = new Velo();
        //allow tester to mint tokens
        veloToken.setRedemptionReceiver(tester);
        //create nft contract for voting escrow
        VeArtProxy artProxy = new VeArtProxy();
        veNFT = new VotingEscrow(address(veloToken), address(artProxy));
        //create voting contract to deal with all bribes and gauges
        voter = new Voter(
            address(veNFT),
            address(velodromeFactory),
            address(gaugeFactory),
            address(bribeFactory)
        );
        vm.stopPrank();
    }

    function testEscrow() public {
        vm.startPrank(tester);
        //get VELO tokens to escrow
        veloToken.mint(tester, 100 ether);
        veloToken.approve(address(veNFT), 100 ether);
        uint nftId = veNFT.create_lock(10 ether, 7 days);
        assertEq(veloToken.balanceOf(tester), 90 ether);
        vm.warp(block.timestamp + 8 days);
        veNFT.withdraw(nftId);
        assertEq(veloToken.balanceOf(tester), 100 ether);
        vm.stopPrank();
    }

    function testCreateGauge() public startWithLiquidity {
        vm.startPrank(tester);
        address pair = velodromeFactory.getPair(
            address(testToken1),
            address(testToken2),
            true
        );
        address gaugeAddress = voter.createGauge(pair);
        assert(voter.isGauge(gaugeAddress));
        assertEq(voter.poolForGauge(gaugeAddress), pair);
        vm.stopPrank();
    }
}
