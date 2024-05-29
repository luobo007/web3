/*
 * @作者: kerwin
 */
const Contacts = artifacts.require("StudentListStorage.sol")

module.exports = function(deployer){
    deployer.deploy(Contacts)
}