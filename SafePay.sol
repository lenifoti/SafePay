// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract SafePay {
    constructor (){}

    uint256 treasury = 0;

    uint256 fee = 10**15;
    uint256 deposit = 10**15;
    
    struct PaymentRequest {
        address payee;
        address payer;
        address tokenAddress; // 0 means ETH
        uint256 amount;
    }

    mapping (uint256 => PaymentRequest) outstandingRequestMap;

    event PaymentRequestEvent(address _payer, address _tokenAddress, uint256 _amount /*string _reason*/);
    event PaymentCancelledEvent(uint256 _outstandingRequestn);
    event PaymentCompleteEvent(uint256 _outstandingRequest, string _tokenSymbol);

    function getFee() public view returns (uint256) {return fee;}
    function getDeposit() public view returns (uint256) {return fee;}

    function newPayment(address payable _payer, address _tokenAddress, uint256 _amount /*string _reason*/) public payable returns (uint256){
        require(msg.value == deposit, "SafePay:bad deposit");
        address payee = msg.sender;
        uint256 rq = uint256(keccak256(abi.encodePacked(_payer,msg.sender,_tokenAddress,_amount)));
        outstandingRequestMap[rq] = PaymentRequest(payee,_payer, _tokenAddress, _amount);
        emit PaymentRequestEvent( _payer, _tokenAddress, _amount /*_reason*/);
        treasury += msg.value;
        return rq;
    }

    function cancelPayment(uint256 _outstandingRequest) public {
        require(outstandingRequestMap[_outstandingRequest].payee == msg.sender, "SafePay:Not payee");
        delete outstandingRequestMap[_outstandingRequest]; //how do we do this?
        emit PaymentCancelledEvent(_outstandingRequest);


    }

    function pay(uint256 _outstandingRequest,
        address payable _payee,
        address _tokenAddress, 
        uint256 _amount,
        string memory _tokenSymbol) public payable{
        PaymentRequest memory req = outstandingRequestMap[_outstandingRequest];
        //would it be cheapert to compare hashes?
        require (req.payer == msg.sender, "SafePay: Not payer");
        require (req.payee == _payee, "SafePay: Not payer");
        require (req.tokenAddress == _tokenAddress, "SafePay: Not payer");
        require (req.amount == _amount, "SafePay: Not payer");
        bytes memory s = bytes(IERC20Metadata(req.tokenAddress).symbol());
        for (uint8 i=0; i<bytes(_tokenSymbol).length; i++) {
            require (i<=bytes(s).length && bytes(_tokenSymbol)[i] == s[i], "SafePay: Wrong token");
        }
        IERC20(req.tokenAddress).transferFrom(msg.sender, req.payer, req.amount);
        payable(req.payer).transfer(deposit);
        emit PaymentCompleteEvent(_outstandingRequest, _tokenSymbol);

        
        treasury += msg.value;


    }
    function cleanUp() public{}

    fallback () external payable {
        treasury += msg.value;
    }

    receive () external payable {
        treasury += msg.value;
    }
}
