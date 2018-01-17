/*
* This is the source code of the smart contract for the IaS Money token.
*/

pragma solidity ^0.4.19;

// ERC Token standard #20 Interface
// https://github.com/ethereum/EIPs/issues/20
contract ERC20Interface {

    // Token symbol
    string public symbol;

    // Name of token
    string public name;

    // Decimals of token
    uint8 public decimals;

    // Total token supply
    function totalSupply() public constant returns (uint256 supply);

    // The balance of account with address _owner
    function balanceOf(address _owner) public constant returns (uint256 balance);

    // Send _value tokens to address _to
    function transfer(address _to, uint256 _value) public returns (bool success);

    // Send _value tokens from address _from to address _to
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    // this function is required for some DEX functionality
    function approve(address _spender, uint256 _value) public returns (bool success);

    // Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


// Implementation of ERC20Interface
contract ERC20Token is ERC20Interface{

    // account balances
    mapping(address => uint256) internal balances;

    // Owner of account approves the transfer of amount to another account
    mapping(address => mapping (address => uint256)) internal allowed;

    // Function to access acount balances
    function balanceOf(address _owner) public constant returns (uint256) {
        return balances[_owner];
    }

    // Transfer the _amount from msg.sender to _to account
    function transfer(address _to, uint256 _amount) public returns (bool) {
        return executeTransfer(msg.sender, _to, _amount);
    }

    // Send _value amount of tokens from address _from to address _to
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public returns (bool) {
        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount && _amount > 0
                && balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount) public returns (bool) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    // Function to specify how much _spender is allowed to transfer on _owner's behalf
    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return allowed[_owner][_spender];
    }

    // Internal function to execute transfer
    function executeTransfer(address _from, address _to, uint256 _amount) internal returns (bool){
        if (balances[_from] >= _amount && _amount > 0
                && balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

}


contract IaSMoney is ERC20Token {
    // total supply of tokens
    // increased with all eth send to the contract
    uint256 internal maxSupply;

    // Token symbol
    string public symbol = 'ISM';

    // Name of token
    string public name = 'I. & S. Money';

    // Gold = BTC
    uint8 public decimals = 9;

    // unit = 10**decimals
    uint256 public constant unit = 1000000000;

    uint256 public constant price = 1 finney / unit;

    function IaSMoney() public{
        // very scarce 42k coins:
        maxSupply = 42000 * unit;
        balances[this] = maxSupply;
    }

    function () public payable{
        uint256 amount = msg.value / price;
        // ship the tokens to the buyer
        require(executeTransfer(this, msg.sender, amount));
    }

    function totalSupply() public constant returns (uint256){
        return maxSupply;
    }

    function transfer(address _to, uint256 _amount) public returns (bool){
        // first recevie tokens by the seller
        bool success = super.transfer(_to, _amount);
        // send the ETH back to the seller
        if ((_to == address(this)) && success){
            uint256 value = _amount * price;
            msg.sender.transfer(value);
        }
        return success;

    }

}