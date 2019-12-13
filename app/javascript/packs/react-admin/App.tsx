import * as React from 'react';
import { Admin, Resource, EditGuesser } from 'react-admin';
import UserIcon from '@material-ui/icons/Group';
import { createMuiTheme } from '@material-ui/core/styles';
import { red, deepPurple, pink } from '@material-ui/core/colors';

import jsonServerProvider from './data-providers/ra-data-json-server';
import { Dashboard } from './views/dashboard';
import { RobotList, RobotCreate, RobotEdit } from './views/robots'
import { UserList, UserEdit, UserCreate, UserShow } from './views/users';

const dataProvider = jsonServerProvider('http://localhost:3000/api/v2/admin');

const theme = createMuiTheme({
  palette: {
    // type: 'dark',
    primary: pink,
    secondary: deepPurple,
    error: red,
  },
});

const App = () => (
  <Admin dashboard={Dashboard} dataProvider={dataProvider} theme={theme} title={'ArkeAdmin'}>
    <Resource name="robots" list={RobotList} edit={RobotEdit} create={RobotCreate} />
    <Resource name="users" icon={UserIcon} list={UserList} edit={UserEdit} create={UserCreate} show={UserShow} />
  </Admin>
);

export default App;
