/*
 * @作者: kerwin
 */
import React from 'react';
import { Card, Col, Row,Button, Table,Statistic } from 'antd';
import {useSelector} from "react-redux";
import moment from "moment";

function converTime(t){
    return moment(t * 1000).format("YYYY/MM/DD HH:mm:ss");
}

function convert(n) {
    //window.web
    if (!window.web || !n) return
    return window.web.web3.utils.fromWei(n, "ether");
}

function getRenderOrder(order,type){
    if(!window.web) return []

    const account=window.web.account
     //1.排除已完成以及取消订单
    let filterIds=[...order.CancelOrders,...order.FillOrders].map(item=>item.id);
    let pendingOrders=order.AllOrders.filter(item=>!filterIds.includes(item.id));
    console.log(pendingOrders);
  
    if(type===1){
        return pendingOrders.filter(item=>item.user===account)
    }else{
        return pendingOrders.filter(item=>item.user!==account)
    }
     //2.account

}

export default function Order() {
    
    const order=useSelector(state=> state.order)
    console.log(order)
    const columns = [
        {
            title: '时间',
            dataIndex: 'timestamp',
            render:(timestamp)=><b>{ converTime(timestamp)}</b>
            
        },
        {
            title: 'KWT',
            dataIndex: 'amountGet',
            render:(amountGet)=><b>{ convert(amountGet)}</b>
        },
        {
            title: 'ETH',
            dataIndex: 'amountGive',
            render:(amountGive)=><b>{ convert(amountGive)}</b>
        },
    ];

    const columns1 = [
        ...columns,{
            title: '操作',
            render:(item)=><Button type="primary" onClick={()=>{
                const {exchange,account}=window.web
                exchange.methods.cancelOrder(item.id).send({from:account})
            }}>取消</Button>
        }
    ];

    const columns2 = [
        ...columns,{
            title: '操作',
            render:(item)=><Button danger onClick={()=>{
                const {exchange,account}=window.web
                exchange.methods.fillOrder(item.id).send({from:account})
            }}>买入</Button>
        }
    ];

    return (
        <div style={{ marginTop: "10px" }}>
            <Row >
                <Col span={8}>
                    <Card title="已完成交易" hoverable="true" style={{ margin: 10 }}>
                        <Table dataSource={order.FillOrders} columns={columns} rowKey={item=>item.id} />;
                    </Card>
                </Col>

                <Col span={8}>
                    <Card title="交易中-我创建的订单" hoverable="true" bordered={false} style={{ margin: 10 }}>
                    <Table dataSource={getRenderOrder(order,1)} columns={columns1} rowKey={item=>item.id} />;
                    </Card>
                </Col>

                <Col span={8}>
                    <Card title="交易中-其他人的订单" hoverable="true" bordered={false} style={{ margin: 10 }}>
                    <Table dataSource={getRenderOrder(order,2)} columns={columns2} rowKey={item=>item.id} />;
                    </Card>
                </Col>
            </Row>
        </div>
    )
}
