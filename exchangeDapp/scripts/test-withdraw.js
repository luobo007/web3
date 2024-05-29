/*
 * @作者: kerwin
 */
const KerwinToken = artifacts.require("KerwinToken.sol")
const Exchange = artifacts.require("Exchange.sol")
const ETHER_ADDRESS = '0x0000000000000000000000000000000000000000' 


const fromWei = (bn)=>{
    return web3.utils.fromWei(bn,"ether");
}

const toWei = (number)=>{
    return web3.utils.toWei(number.toString(),"ether");
}

module.exports = async function (callback){
    const kerwintoken =await KerwinToken.deployed()
    const exchange =await Exchange.deployed()
    const accounts= await web3.eth.getAccounts()

    // await exchange.withdrawEther(toWei(5),{
    //     from:accounts[0]
    // })
    // let res = await exchange.tokens(ETHER_ADDRESS,accounts[0])
    // console.log(fromWei(res))

    //授权
    // await kerwintoken.approve(exchange.address,toWei(100000),{
    //     from:accounts[0]
    // }) 
    await exchange.withdrawToken(kerwintoken.address,toWei(50000),{
        from:accounts[0]
    })
    
    let res = await exchange.tokens(kerwintoken.address,accounts[0])
    console.log(fromWei(res))

    callback()
}