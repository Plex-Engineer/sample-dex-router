pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "src/velodrome/Velo.sol";
import "src/velodrome/VeArtProxy.sol";
import "src/velodrome/factories/PairFactory.sol";
import {VotingEscrow} from "src/velodrome/VotingEscrow.sol";
import {GaugeFactory} from "src/velodrome/factories/GaugeFactory.sol";
import {BribeFactory} from "src/velodrome/factories/BribeFactory.sol";
import {RewardsDistributor} from "src/velodrome/RewardsDistributor.sol";
import {Voter} from "src/velodrome/Voter.sol";
import {Minter} from "src/velodrome/Minter.sol";

contract DeployVelodrome is Script {
    function run() external {
        uint deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        //create factories
        GaugeFactory gaugeFactory = new GaugeFactory();
        BribeFactory bribeFactory = new BribeFactory();
        PairFactory velodromeFactory = new PairFactory();
        //create token for rewards
        Velo veloToken = new Velo();
        //create nft contract for voting escrow
        VeArtProxy artProxy = new VeArtProxy();
        VotingEscrow veNFT = new VotingEscrow(
            address(veloToken),
            address(artProxy)
        );
        //create voting contract to deal with all bribes and gauges
        Voter voter = new Voter(
            address(veNFT),
            address(velodromeFactory),
            address(gaugeFactory),
            address(bribeFactory)
        );
        //create rewards distributor contract
        RewardsDistributor rewardsDist = new RewardsDistributor(address(veNFT));
        //create minter contract to mint velo tokens
        Minter minter = new Minter(
            address(voter),
            address(veNFT),
            address(rewardsDist)
        );

        //initialze all contracts
        //set the minter for VELO to the minter
        veloToken.setMinter(address(minter));
        //point the voter to the minter and pass in starting whitelist
        address[] memory initialWhitelist;
        voter.initialize(initialWhitelist, address(minter));
        //initialize minter with starting balance of Velo
        address[] memory claimants;
        uint[] memory amounts;
        minter.initialize(claimants, amounts, 1000000 ether);

        vm.stopBroadcast();
        console.log("pair factory address: ", address(velodromeFactory));
        console.log("velo token address: ", address(veloToken));
        console.log("veNFT address: ", address(velodromeFactory));
        console.log("voter contract address: ", address(voter));
        console.log("rewards dist address: ", address(rewardsDist));
        console.log("minter address: ", address(minter));
    }
}
