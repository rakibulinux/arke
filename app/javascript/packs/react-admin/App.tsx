import * as React from 'react';
import { Admin, Resource } from 'react-admin';
import UserIcon from '@material-ui/icons/Group';
import { createMuiTheme } from '@material-ui/core/styles';
import { red } from '@material-ui/core/colors';

import jsonServerProvider from './data-providers/ra-data-json-server';
import { Dashboard } from './dashboard';
import { RobotList, RobotCreate, RobotEdit } from './robots'
import AccountList from './accounts/AccountList'


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
  overrides: {}
  //   MuiCard: { // padding for account form
  //     root: {
  //       padding: '8px',
  //       paddingBottom: '18px',
  //     }
  //   },
  //   MuiCardHeader: {
  //     root: {
  //       paddingBottom: '0px',
  //     }
  //   }
  // }
});

const App = () => (
  <Admin dashboard={Dashboard} dataProvider={dataProvider} theme={theme} title={'ArkeAdmin'}>
    <Resource name="robots" list={RobotList} edit={RobotEdit} create={RobotCreate} />
    <Resource name="accounts" icon={UserIcon} list={AccountList} />
    <Resource name="exchanges" />
  </Admin>
);

export default App;
