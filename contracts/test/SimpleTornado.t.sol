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
    struct ProofData {
        uint256 a1;
        uint256 a2;
        uint256 b1;
        uint256 b2;
        uint256 c1;
        uint256 c2;
        uint256 z1;
        uint256 z2;
        uint256 t1_1;
        uint256 t1_2;
        uint256 t2_1;
        uint256 t2_2;
        uint256 t3_1;
        uint256 t3_2;
        uint256 wxi1;
        uint256 wxi2;
        uint256 wxiw1;
        uint256 wxiw2;
        uint256 evala;
        uint256 evalb;
        uint256 evalc;
        uint256 evals1;
        uint256 evals2;
        uint256 evalzw;
    }
    struct PublicSignals {
        uint256 nullifier;
        uint256 commitment;
        uint256 x;
        uint256 y;
        uint256 amount;
        uint256 tokenId;
        uint256 z;
    }

    string s = "hello world";

    address alice = vm.addr(2);
    address bob = vm.addr(3);

    uint256 tokenId = 1;
    uint256 tokenIdSecond = 2;
    uint256 amount = 1000000000000000000;

    ProofData proofData =
        ProofData({
            a1: 18650127154255266287357815007049411831929718174853670124347470859207595524096,
            a2: 18010354519736823805744293961024234332700078027229333430868174235663987638272,
            b1: 3997346565847707970240202723164513208688505691122685653376052922269898375168,
            b2: 12140219447630057730254272964763991691652304554186492796434705339103712378880,
            c1: 8244254993594412829638491738423570274478915439392237409204613532036160815104,
            c2: 8598512536859150994353162942044440791404183401791314673636872926476166496256,
            z1: 6350161879995928822145995615310855613819801036968264568731245998911019548672,
            z2: 10308704221272112562170480681174074070577813157722934475300149259909516492800,
            t1_1: 16513706672514035424688375230988063680859744737435917861251167993878892511232,
            t1_2: 16477634256557577450827861276758273114942347727451876337656157389658985070592,
            t2_1: 19952119849002896389978873626961725593541780399544937366299190151972604870656,
            t2_2: 5671021443012524025547816681039918246642082753810336637704677087666052792320,
            t3_1: 19044165176016644879143125930051713849731714155050188633820571293013529067520,
            t3_2: 7684166421040525401590793664214402726128426674073326934946889130916263755776,
            wxi1: 15211971172482187878052094820609475054711707827136391986436554991501670612992,
            wxi2: 9419932377356431701297531719477268262441287475783970169260070412525544407040,
            wxiw1: 15124609192652320756941727837850853950497284715045836245414435788109115293696,
            wxiw2: 16445310947203962143898464191655726091712208946382531465651332163786961321984,
            evala: 334150627594518511433504220085592789552816257154154519816915339665330929664,
            evalb: 21384237702159563738957514972060375893809194692312158998812146730969407160320,
            evalc: 8000660250981985139225895129083162782387903600673369012732189248937630105600,
            evals1: 7438477065631275190769600852067551576898960482724855274943515765377349976064,
            evals2: 939971015174356088171116353941845857492341065170288174812809812133600559104,
            evalzw: 330224144211666454296152284917742604927281718620715050444776592381998792704
        });

    PublicSignals publicSignals =
        PublicSignals({
            nullifier: 19878124789532411266873454094155986872113090957688922333185217385509569151759,
            commitment: 8291582024945179365426271505448992562261860026503440184359539280877127275159,
            x: 17393678536986902832044454704805575356618420657351844439869897747913785069068,
            y: 123123,
            amount: 1000000000000000000,
            tokenId: 1,
            z: 1210839035359465216
        });

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
        vm.startPrank(alice);
        token.approve(address(tornado), tokenId, amount);
        tornado.deposit(publicSignals.commitment, tokenId, 1000000000000000000); // deposit 1 token

        assertEq(token.balanceOf(alice, tokenId), 999000000000000000000);
        assertEq(
            token.balanceOf(address(tornado), tokenId),
            1000000000000000000
        );
        vm.stopPrank();

        vm.startPrank(alice);
        token.approve(address(tornado), tokenId, amount);

        vm.expectRevert(bytes("Commitment already exists"));
        tornado.deposit(publicSignals.commitment, tokenId, amount);

        vm.stopPrank();
    }

    function test_withdraw() public {
        uint256 depositAmount = 1000000000000000000;

        vm.startPrank(alice);

        token.approve(address(tornado), tokenId, amount);
        tornado.deposit(publicSignals.commitment, tokenId, depositAmount); // deposit 1 token

        vm.stopPrank();

        bytes memory proofBytes = abi.encode(proofData, publicSignals);

        vm.startPrank(bob);
        tornado.withdraw(proofBytes);

        // withdraw again
        vm.expectRevert(bytes("Nullifier already exists"));
        tornado.withdraw(proofBytes);
        vm.stopPrank();

        assertEq(token.balanceOf(bob, tokenId), depositAmount);
    }
}
