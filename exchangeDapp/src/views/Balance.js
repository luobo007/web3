/*
 * @作者: kerwin
 */
import React from 'react'
import { useSelector } from 'react-redux'
import { Card, Col, Row, Statistic } from 'antd';

function convert(n) {
    //window.web
    if (!window.web) return
    return window.web.web3.utils.fromWei(n, "ether");
}

export default function Balance() {
    const {
        TokenWallet,
        TokenExchange,
        EtherWallet,
        EtherExchange,
    } = useSelector(state => state.balance)
    return (
        <div>
            <Row >
                <Col span={6}>
                    <Card hoverable="true">
                        <Statistic
                            title="钱包中以太币"
                            value={convert(EtherWallet)}
                            precision={2}
                            valueStyle={{ color: '#3f8600' }}
                        />
                    </Card>
                </Col>
                <Col span={6}>
                    <Card hoverable="true">
                        <Statistic
                            title="钱包中KWT"
                            value={convert(TokenWallet)}
                            precision={2}
                            valueStyle={{ color: '#1677ff' }}
                        />
                    </Card>
                </Col>
                <Col span={6}>
                    <Card hoverable="true">
                        <Statistic
                            title="交易所中以太币"
                            value={convert(EtherExchange)}
                            precision={2}
                            valueStyle={{ color: '#faad14' }}
                        />
                    </Card>
                </Col>
                <Col span={6}>
                    <Card hoverable="true">
                        <Statistic
                            title="交易所中KWT"
                            value={convert(TokenExchange)}
                            precision={2}
                            valueStyle={{ color: '#cf1332' }}
                        />
                    </Card>
                </Col>
            </Row>
           
        </div>
    )
}
