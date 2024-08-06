// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";

import {Test, console} from "forge-std/Test.sol";
import {BasicTornado} from "../src/BasicTornado.sol";
import {PlonkVerifier} from "../src/WithdrawVerifier.sol";
import {ZKFToken} from "../src/ZKFToken.sol";

contract ZKFTokenTest is Test {
    ZKFToken public token;
    BasicTornado public tornado;
    PlonkVerifier public verifier;

    address alice = vm.addr(2);
    address bob = vm.addr(3);

    uint256 tokenId = 1;
    uint256 tokenIdSecond = 2;
    uint256 amount = 1000000000000000000000; // 100 tokens

    uint256[7] public publicSignals = [
        10780830691781017420074439787495958877950596246159245786151402679131682618750,
        7106845738133882086345912894961481425204400941108340403951013321794263700711,
        20174539379539423050504750187002670232292930346096343810711356488132818469794,
        9999999999,
        1000000000000000000,
        1,
        1234567890
    ];

    uint256[2] public a = [
        2484467961901526357083659677031275139843656012942112113765699821739119702628,
        11959036481709733614119226342680436296439419213041010636913954999137095586332
    ];

    uint256[2] public b = [
        2857441107104185593692710824202919117020160016161113634344772943305527282947,
        14677478741347713623170393014500786724756291000333821499258062672337300722654
    ];
    uint256[2] public c = [
        21329309929980340729463624826291021064406442718758978053225748351426031369407,
        4916216972169679723703383657260607669762268258045044245420808195838751234840
    ];
    uint256[2] public z = [
        9184884180169809047488723221979690554844359148125565406479738386528129794994,
        9009230401254754576192143172670718482394870762285844485463456541918435101887
    ];

    uint256[2] public t1 = [
        11825233313143736679535916128651110722961716688636654169224604319366600329129,
        6889428171706345515742503933395985017261322813544120714401904162659690939797
    ];
    uint256[2] public t2 = [
        10217222535523388167367166704893500697867665378711950159449932965469321318832,
        2741859554924974728183861124697521433388373998645694049862064167749149398420
    ];
    uint256[2] public t3 = [
        3640681002032186017403659148108557193401381948106722990158991323908471507896,
        21158004818670024701410308102019265001767508866561366667297495655022736787722
    ];
    uint256[2] public wxi = [
        1598529850084995528563123739249910144058656933910048578038838688942162627484,
        4126228238992420396192411974016647195529589031558829699508163015671165523588
    ];
    uint256[2] public wxiw = [
        17439816512363417859180456343286741590753242873659857837948001582563994605091,
        19317132629591594021041727055348337415144229769669142073173197494306503965802
    ];
    uint256 public eval_a =
        14548396325720430630357151823799804987373982038026153087952652365015940629129;
    uint256 public eval_b =
        9206853833996251225363346766237184078437704408127920434354895401958317100620;
    uint256 public eval_c =
        1507140055648755532974673867430282569498993505589454777416030065980233254815;
    uint256 public eval_s1 =
        681420461986600119356068440998365542464659569268150236412595059142686800509;
    uint256 public eval_s2 =
        14277016146595286161126401855495652136515829390235907478081562491270792191169;
    uint256 public eval_zw =
        18725595167548806965642892125513977824793797613137214133363693200923325080643;

    function setUp() public {
        token = new ZKFToken();
        verifier = new PlonkVerifier();
        tornado = new BasicTornado(token, verifier);

        // mint tokens for alice and bob
        token.mint(alice, tokenId, amount);
        token.mint(bob, tokenIdSecond, amount);
    }

    function test_balanceOf() public view {
        assertEq(token.balanceOf(alice, tokenId), amount);
        assertEq(token.balanceOf(bob, tokenIdSecond), amount);
    }

    function test_deposit() public {
        bytes32 commitment = bytes32(keccak256(abi.encode(publicSignals[1])));

        vm.startPrank(alice);
        token.approve(address(tornado), tokenId, amount);
        tornado.deposit(commitment, tokenId, 1000000000000000000); // deposit 1 token

        assertEq(token.balanceOf(alice, tokenId), 999000000000000000000);
        assertEq(
            token.balanceOf(address(tornado), tokenId),
            1000000000000000000
        );
        vm.stopPrank();

        vm.startPrank(alice);
        token.approve(address(tornado), tokenId, amount);

        vm.expectRevert(bytes("Commitment already exists"));
        tornado.deposit(commitment, tokenId, amount);

        vm.stopPrank();
    }

    function test_withdraw() public {
        uint256 depositAmount = 1000000000000000000;

        vm.startPrank(alice);
        bytes32 commitment = bytes32(keccak256(abi.encode(publicSignals[1])));
        token.approve(address(tornado), tokenId, amount);
        tornado.deposit(commitment, tokenId, depositAmount); // deposit 1 token
        vm.stopPrank();

        bytes memory proof = abi.encode(
            a[0],
            a[1],
            b[0],
            b[1],
            c[0],
            c[1],
            z[0],
            z[1]
        );
        bytes memory proof1 = abi.encode(
            t1[0],
            t1[1],
            t2[0],
            t2[1],
            t3[0],
            t3[1],
            wxi[0],
            wxi[1],
            wxiw[0],
            wxiw[1]
        );
        bytes memory proof2 = abi.encode(
            eval_a,
            eval_b,
            eval_c,
            eval_s1,
            eval_s2,
            eval_zw
        );
        bytes memory proofPacked = abi.encode(proof, proof1, proof2);

        bytes memory publicSignalsData = abi.encode(
            publicSignals[0],
            publicSignals[1],
            publicSignals[2],
            publicSignals[3],
            publicSignals[4],
            publicSignals[5],
            publicSignals[6]
        );

        bytes memory proofData = abi.encode(proofPacked, publicSignalsData);

        vm.startPrank(bob);
        tornado.withdraw(proofData);

        // withdraw again
        vm.expectRevert(bytes("Nullifier already exists"));
        tornado.withdraw(proofData);
        vm.stopPrank();

        assertEq(token.balanceOf(bob, tokenId), depositAmount);
    }
}
