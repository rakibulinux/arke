import * as React from 'react';
import * as ReactDOM from 'react-dom';
import './react-admin/index.css';
import App from './react-admin/App';
import * as serviceWorker from './react-admin/serviceWorker';

document.addEventListener('DOMContentLoaded', () => {
  ReactDOM.render(<App />, document.body.appendChild(document.createElement('div')));
});

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
serviceWorker.unregister();
