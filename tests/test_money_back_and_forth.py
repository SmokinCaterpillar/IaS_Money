from ethereum.tester import TransactionFailed
from ethereum.exceptions import InvalidTransaction
import pytest

ether = int(1e18)
finney = int(ether/1000)
vig = 10
decimals = 9
unit = int(1e9)
price = 1 * finney
total_supply = 42000 * unit
null_address = '0x0000000000000000000000000000000000000000'


def get_wei(chain, accounts):
    """ Returns the wei for each address in `accounts`

    :param chain: populus chain interface
    :param accounts: List of adresses
    :return: List of weis
    """
    web3 = chain.web3
    weis = []
    for irun, account in enumerate(accounts):
        wei = web3.eth.getBalance(accounts[irun])
        weis.append(wei)
    return weis


def test_init(chain, accounts):

    provider = chain.provider
    ias_money, deploy_txn_hash = provider.get_or_deploy_contract('IaSMoney')

    # Check some initial settings:
    assert ias_money.call().balanceOf(ias_money.address) == total_supply
    assert ias_money.call().balanceOf(accounts[1]) == 0
    assert ias_money.call().totalSupply() == total_supply
    assert ias_money.call().name() == 'I. & S. Money'
    assert ias_money.call().symbol() == 'ISM'
    assert ias_money.call().decimals() == decimals


def test_buy_and_sell(chain, accounts, web3):

    provider = chain.provider
    ias_money, deploy_txn_hash = provider.get_or_deploy_contract('IaSMoney')

    initial = web3.eth.getBalance(accounts[1])
    chain.wait.for_receipt(web3.eth.sendTransaction({'value':10*price,
                                                     'from':accounts[1],
                                                     'to': ias_money.address,
                                                     'gas':200000}))

    after = web3.eth.getBalance(accounts[1])

    assert ias_money.call().balanceOf(accounts[1]) == 10 * unit
    assert after <= initial - 10*price

    chain.wait.for_receipt(ias_money.transact({'from':accounts[1]}).transfer(accounts[2], 5 * unit))

    assert ias_money.call().balanceOf(accounts[1]) == 5 * unit
    assert ias_money.call().balanceOf(accounts[2]) == 5 * unit

    chain.wait.for_receipt(ias_money.transact({'from':accounts[1]}).transfer(ias_money.address,
                                                                             5 * unit))

    sold = web3.eth.getBalance(accounts[1])

    assert ias_money.call().balanceOf(accounts[1]) == 0
    assert sold > after + 4.9*price

    after = web3.eth.getBalance(accounts[2])

    chain.wait.for_receipt(ias_money.transact({'from':accounts[2]}).transfer(ias_money.address,
                                                                             4 * unit))
    sold = web3.eth.getBalance(accounts[2])

    assert ias_money.call().balanceOf(accounts[2]) == 1 * unit
    assert sold > after + 3.99*price