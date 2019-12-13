import * as React from 'react';
import { Admin, Resource, ListGuesser } from 'react-admin';
import UserIcon from '@material-ui/icons/Group';
import { createMuiTheme } from '@material-ui/core/styles';
import { red, deepPurple, pink } from '@material-ui/core/colors';

import jsonServerProvider from './data-providers/ra-data-json-server';
import { Dashboard } from './views/dashboard';
import { RobotList, RobotCreate, RobotEdit } from './views/robots'

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
  <Admin dashboard={Dashboard} dataProvider={dataProvider} theme={theme}>
    <Resource name="robots" list={RobotList} icon={UserIcon} edit={RobotEdit} create={RobotCreate} />
    <Resource name="users" list={ListGuesser} />
  </Admin>
);

export default App;
