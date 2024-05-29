/*
 * @作者: kerwin
 */
const KerwinToken = artifacts.require("KerwinToken.sol")
const Exchange = artifacts.require("Exchange.sol")
const ETHER_ADDRESS = '0x0000000000000000000000000000000000000000' // 0x 后面 40 个 0


const fromWei = (bn) => {
    return web3.utils.fromWei(bn, "ether");
}

const toWei = (number) => {
    return web3.utils.toWei(number.toString(), "ether");
}

const wait = (seconds) => {
    const milliseconds = seconds * 1000
    return new Promise((resolve) => setTimeout(resolve, milliseconds))
}


module.exports = async function (callback) {
    try {
        const kerwintoken = await KerwinToken.deployed()
        const exchange = await Exchange.deployed()
        const accounts = await web3.eth.getAccounts()

        for (let i = 1; i <= 5; i++) {
            await exchange.makeOrder(
                kerwintoken.address,
                toWei(10+i),
                ETHER_ADDRESS,
                toWei(i/100),
                { from: accounts[0] }
            )
            console.log(`accounts[0] 制作第 ${i} 个账单`)
            await wait(1)
        }

        for (let i = 1; i <= 5; i++) {
            await exchange.makeOrder(
                kerwintoken.address,
                toWei(100+i),
                ETHER_ADDRESS,
                toWei(i/10),
                { from: accounts[1] }
            )
            console.log(`accounts[1] 制作第 ${i} 个账单`)
            await wait(1)
        }
    } catch (error) {
        console.log(error)
    }


    callback()
}