import React from 'react'
import Content from './views/Content'
import {Provider} from 'react-redux'
import store from './redux/store'
export default function App() {
  return (
    <Provider store= {store}>
       <Content></Content>
    </Provider>
  )
}
