/*
 * @作者: kerwin
 */
import {createSlice,createAsyncThunk} from "@reduxjs/toolkit"
const ETHER_ADDRESS = '0x0000000000000000000000000000000000000000' // 0x 后面 40 个 0


const balanceSlice = createSlice({
    name:"balance", // type: balance/get,,,
    initialState:{
        TokenWallet:"0", //wei转换， 需要字符串， 不是数字0
        TokenExchange:"0",
        EtherWallet:"0",
        EtherExchange:"0"
    },
    reducers:{
        setTokenWallet(state,action){
            state.TokenWallet = action.payload
        },
        setTokenExchange(state,action){
            state.TokenExchange = action.payload
        },
        setEtherWallet(state,action){
            state.EtherWallet = action.payload
        },
        setEtherExchange(state,action){
            state.EtherExchange = action.payload
        }
    }
})

export const {setTokenWallet,setTokenExchange,setEtherWallet,setEtherExchange} = balanceSlice.actions

export default balanceSlice.reducer;
//balanceSlice.action


export const loadBalanceData = createAsyncThunk(
    "balance/fetchBalanceData",
    async (data, {dispatch}) =>{
        // console.log(data)
        const {web3,
            account,
            token,
            exchange} = data

        // 获取钱包的token
        const TokenWallet = await token.methods.balanceOf(account).call()

        dispatch(setTokenWallet(TokenWallet))
        // 获取交易所的token
        // console.log(token.options.address)
        const TokenExchange = await exchange.methods.balanceOf(token.options.address,account).call()

        dispatch(setTokenExchange(TokenExchange))
        // 获取钱包 ether

        const EtherWallet = await web3.eth.getBalance(account)

        dispatch(setEtherWallet(EtherWallet))
        // 获取交易所的 ether

        const EtherExchange = await exchange.methods.balanceOf(ETHER_ADDRESS,account).call()

        dispatch(setEtherExchange(EtherExchange))
    }
)