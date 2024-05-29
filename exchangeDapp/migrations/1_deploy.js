/*
 * @作者: kerwin
 */
const Contacts = artifacts.require("StudentStorage.sol")

module.exports = function(deployer){
    deployer.deploy(Contacts)
}