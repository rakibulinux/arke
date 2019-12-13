import * as React from 'react';
import {
  Create,
  Datagrid,
  DateField,
  Edit,
  EmailField,
  Filter,
  List,
  NumberInput,
  NumberField,
  SimpleForm,
  SimpleShowLayout,
  Show,
  SelectInput,
  TextField,
  TextInput
} from 'react-admin';

const UserFilter = props => (
  <Filter {...props}>
    <TextInput source="level" />
    <TextInput source="email" alwaysOn />
    <TextInput source="uid" alwaysOn />
    <SelectInput source="role" choices={[
      { name: 'Admin', id: 'admin' },
      { name: 'Trader', id: 'trader' },
      { name: 'Broker', id: 'broker' },
    ]} />
  </Filter>
);

const UserForm = props => (
  <SimpleForm {...props}>
    <TextInput source="uid" />
    <TextInput source="email" />
    <NumberInput source="level" />
    <TextInput source="role" />
    <TextInput source="state" />
  </SimpleForm>
);

export const UserList = props => (
  <List filters={<UserFilter />} {...props}>
    <Datagrid rowClick="edit">
      <TextField source="id" />
      <TextField source="uid" />
      <EmailField source="email" />
      <NumberField source="level" />
      <TextField source="role" />
      <TextField source="state" />
      <DateField source="created_at" />
      <DateField source="updated_at" />
    </Datagrid>
  </List>
);

export const UserEdit = props => (
  <Edit {...props}>
    <UserForm />
  </Edit>
);

export const UserCreate = props => (
  <Create {...props}>
    <UserForm />
  </Create>
);

export const UserShow = props => (
  <Show title="User" {...props}>
    <SimpleShowLayout>
      <TextField source="uid" />
      <TextField source="email" />
      <NumberField source="level" />
      <TextField source="role" />
      <TextField source="state" />
    </SimpleShowLayout>
  </Show>
);
