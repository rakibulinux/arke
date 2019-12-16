import * as React from 'react';
import { Admin, Resource, EditGuesser, ListGuesser } from 'react-admin';
import UserIcon from '@material-ui/icons/Group';
import { createMuiTheme } from '@material-ui/core/styles';
import { red } from '@material-ui/core/colors';

import jsonServerProvider from './data-providers/ra-data-json-server';
import { Dashboard } from './dashboard';
import { RobotList, RobotCreate, RobotEdit } from './robots'
import { AccountEdit, AccountCreate } from './accounts';
import AccountList from './accounts/accountList'


const dataProvider = jsonServerProvider('http://localhost:3000/api/v2');

const theme = createMuiTheme({
  palette: {
    primary: {
      main: '#219653',
    },
    secondary: {
      main: '#219653',
    },
    error: red,
  },
});

const App = () => (
  <Admin dashboard={Dashboard} dataProvider={dataProvider} theme={theme} title={'ArkeAdmin'}>
    <Resource name="robots" list={RobotList} edit={RobotEdit} create={RobotCreate} />
    <Resource name="accounts" icon={UserIcon} list={AccountList} />
    <Resource name="exchanges" icon={UserIcon} list={ListGuesser} />
  </Admin>
);

export default App;
