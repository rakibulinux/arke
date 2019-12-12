import * as React from 'react';
import { Admin, Resource, ListGuesser } from 'react-admin';
import UserIcon from '@material-ui/icons/Group';
import jsonServerProvider from 'ra-data-json-server';

import { Dashboard } from './views/dashboard';
import { RobotList, RobotCreate, RobotEdit } from './views/robots'

const dataProvider = jsonServerProvider('http://localhost:3000/api/v2/admin');

const App = () => (
  <Admin dashboard={Dashboard} dataProvider={dataProvider}>
    <Resource name="robots" list={RobotList} icon={UserIcon} edit={RobotEdit} create={RobotCreate} />
    <Resource name="users" list={ListGuesser} />
  </Admin>
);

export default App;
