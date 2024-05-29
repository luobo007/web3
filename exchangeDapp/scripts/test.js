/*
 * @作者: kerwin
 */
const Contacts = artifacts.require("StudentStorage.sol")

module.exports =async  function(callback){
    // console.log(111111)
    const studentStorage = await Contacts.deployed()

    await studentStorage.setData("kerwin",100)
    let res =await studentStorage.getData()
    console.log(res)
    console.log(await studentStorage.name())
    console.log(await studentStorage.age())
    callback()
}

