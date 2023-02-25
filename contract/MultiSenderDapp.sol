// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title MultiSender, support ETH and ERC20 Tokens, send ether or erc20 token to multiple addresses in batch
*/

library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0);
        uint c = a / b;
        require(a == b * c + a % b);
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a);
        return c;
    }

    function max(uint a, uint b) internal pure returns (uint) {
        return a >= b ? a : b;
    }

    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }
}

contract MultiSender {
    using SafeMath for uint256;

    event TokensSent(address token, uint256 total);
    event TokenReceived(address token, address sender, uint256 amount);
    event ETHReceived(address sender, uint256 amount);
    event VIPAdded(address vip);
    event VIPRemoved(address vip);
    event ReceiverAddressChanged(address newAddress);
    event TxFeeChanged(uint256 newFee);

    address public receiverAddress;
    uint256 public txFee = 0.01 ether;
    mapping(address => bool) public vipList;

    constructor(address _receiverAddress) {
        receiverAddress = _receiverAddress;
    }

    modifier onlyVIP() {
        require(vipList[msg.sender], "Sender is not on the VIP list.");
        _;
    }

    function sendETH(address[] calldata _recipients, uint256[] calldata _values) external payable {
        require(_recipients.length == _values.length, "Array lengths do not match.");
        require(msg.value > txFee.mul(_recipients.length), "Transaction fee not met.");
        uint256 total = 0;
        for (uint256 i = 0; i < _recipients.length; i++) {
            address recipient = _recipients[i];
            uint256 value = _values[i];
            total = total.add(value);
            require(payable(recipient).send(value));
            emit ETHReceived(recipient, value);
        }
        emit TokensSent(address(0), total);
    }

    function sendToken(address _tokenAddress, address[] calldata _recipients, uint256[] calldata _values) external {
        require(_recipients.length == _values.length, "Array lengths do not match.");
        require(_tokenAddress != address(0), "Invalid token address.");
        require(_recipients.length <= 100, "Too many recipients.");
        uint256 total = 0;
        for (uint256 i = 0; i < _recipients.length; i++) {
            address recipient = _recipients[i];
            uint256 value = _values[i];
            require(recipient != address(0), "Invalid recipient address.");
            total = total.add(value);
            require(IERC20(_tokenAddress).transferFrom(msg.sender,
           recipient, value), "Token transfer failed.");
emit TokenReceived(_tokenAddress, msg.sender, value);
}
emit TokensSent(_tokenAddress, total);
}
function addVIP(address _vip) external onlyVIP {
    vipList[_vip] = true;
    emit VIPAdded(_vip);
}

function removeVIP(address _vip) external onlyVIP {
    vipList[_vip] = false;
    emit VIPRemoved(_vip);
}

function setReceiverAddress(address _receiverAddress) external onlyVIP {
    receiverAddress = _receiverAddress;
    emit ReceiverAddressChanged(_receiverAddress);
}

function setTxFee(uint256 _txFee) external onlyVIP {
    txFee = _txFee;
    emit TxFeeChanged(_txFee);
}

function withdrawETH() external onlyVIP {
    payable(msg.sender).transfer(address(this).balance);
}

function withdrawToken(address _tokenAddress) external onlyVIP {
    uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
    require(IERC20(_tokenAddress).transfer(msg.sender, balance), "Token transfer failed.");
}

function getBalance(address _tokenAddress) external view returns (uint256) {
    if (_tokenAddress == address(0)) {
        return address(this).balance;
    } else {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }
}

}

interface IERC20 {
function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
function transfer(address recipient, uint256 amount) external returns (bool);
function balanceOf(address account) external view returns (uint256);
}