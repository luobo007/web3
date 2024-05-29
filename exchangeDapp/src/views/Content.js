/*
 * @作者: kerwin
 */
import {useEffect} from 'react'
import {useDispatch} from 'react-redux'
import Web3 from 'web3'
import tokenjson from '../build/KerwinToken.json'
import exchangejson from '../build/Exchange.json'
import Balance from './Balance'
import Order from './Order'
import { loadBalanceData } from '../redux/slices/balanceSlice'
import { loadCancelOrderData,loadAllOrderData,loadFillOrderData} from '../redux/slices/orderSlice'


export default function Content() {
    const dispatch = useDispatch()
    useEffect( () => {
        async function  start(){
            //1. 获取连接后的合约
            const web = await initWeb()
            console.log(web)
            window.web = web //全局对象，
            //useContext, useReducer
            //订阅发布
            //设置成全局，

            //2. 获取资产信息
            dispatch(loadBalanceData(web))
            //3. 获取订单信息
            dispatch(loadCancelOrderData(web))
            dispatch(loadAllOrderData(web))
            dispatch(loadFillOrderData(web))
            //监听
            web.exchange.events.Order({},(error,event)=>{
                dispatch(loadAllOrderData(web))
            })
            web.exchange.events.Cancel({},(error,event)=>{
                dispatch(loadCancelOrderData(web))

            })
            web.exchange.events.Trade({},(error,event)=>{
                dispatch(loadFillOrderData(web))
                dispatch(loadBalanceData(web))
            })
            
        }
        start()
    }, [dispatch])

    async function initWeb(){
        var web3 = new Web3(Web3.givenProvider || "http://localhost:7545");
     
        //先授权
        let accounts = await web3.eth.requestAccounts()
        console.log(accounts[0])

        //获取networkId
        const networkId = await web3.eth.net.getId();

        const tokenabi = tokenjson.abi
        const tokenaddress = tokenjson.networks[networkId].address
        const token = await new web3.eth.Contract(tokenabi,tokenaddress);


        const exchangeabi = exchangejson.abi
        const exchangeaddress = exchangejson.networks[networkId].address
        const exchange = await new web3.eth.Contract(exchangeabi,exchangeaddress);

        // console.log(exchange)
        return {
            web3,
            account:accounts[0],
            token,
            exchange
        }
    }
    return (
        <div style={{padding:"10px"}}>
            <Balance></Balance>
            <Order></Order>
        </div>
    )
}
