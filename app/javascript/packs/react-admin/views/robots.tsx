import * as React from 'react';
import { List, Datagrid, TextField, DateField, ReferenceField, Edit, Create, SimpleForm, ReferenceInput, SelectInput, TextInput, DateInput } from 'react-admin';
import { UrlField } from '../partials/urlField';

export const RobotList = props => (
  <List {...props}>
      <Datagrid rowClick="edit">
          <TextField source="id" />
          <ReferenceField source="user_id" reference="users">
            <UrlField source="uid" />
          </ReferenceField>
          <TextField source="name" />
          <TextField source="strategy" />
          <TextField source="params" />
          <TextField source="state" />
          <DateField source="created_at" />
          <DateField source="updated_at" />
      </Datagrid>
  </List>
);

export const RobotEdit = props => (
  <Edit {...props}>
      <SimpleForm>
          <TextInput source="id" />
          <ReferenceInput source="user_id" reference="users"><SelectInput optionText="id" /></ReferenceInput>
          <TextInput source="name" />
          <TextInput source="strategy" />
          <TextInput source="params" />
          <TextInput source="state" />
          <DateInput source="created_at" />
          <DateInput source="updated_at" />
      </SimpleForm>
  </Edit>
);

export const RobotCreate = props => (
  <Create {...props}>
      <SimpleForm>
          <ReferenceInput source="user_id" reference="users"><SelectInput optionText="id" /></ReferenceInput>
          <TextInput source="name" />
          <TextInput source="strategy" />
          <TextInput source="params" />
          <TextInput source="state" />
      </SimpleForm>
  </Create>
);
