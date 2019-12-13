import * as React from 'react';
import {
  AutocompleteInput,
  List,
  Datagrid,
  TextField,
  DateField,
  ReferenceField,
  Edit,
  Create,
  ReferenceInput,
  SelectInput,
  SimpleForm,
  TextInput,
} from 'react-admin';

export const RobotList = props => (
  <List {...props}>
    <Datagrid rowClick="edit">
      <TextField source="id" />
      <ReferenceField source="user_id" reference="users">
        <TextField source="uid" />
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
      <ReferenceInput source="user_id" reference="users" helperText="Unique user UID">
        <AutocompleteInput optionText="uid" />
      </ReferenceInput>
      <TextInput source="name" />
      <SelectInput source="strategy" choices={[
        { id: 'copy', name: 'copy' },
        { id: 'orderback', name: 'orderback' },
        { id: 'fixedprice', name: 'fixedprice' },
        { id: 'microtrades', name: 'microtrades' },
      ]} />
      <SelectInput source="state" choices={[
        { id: 'disabled', name: 'disabled' },
        { id: 'enabled', name: 'enabled' },
      ]} />
      <TextInput source="params" />
    </SimpleForm>
  </Edit>
);

export const RobotCreate = props => (
  <Create {...props}>
    <SimpleForm>
    <ReferenceInput source="user_id" reference="users" helperText="Unique user UID">
        <AutocompleteInput optionText="uid" />
      </ReferenceInput>
      <TextInput source="name" />
      <SelectInput source="strategy" choices={[
        { id: 'copy', name: 'copy' },
        { id: 'orderback', name: 'orderback' },
        { id: 'fixedprice', name: 'fixedprice' },
        { id: 'microtrades', name: 'microtrades' },
      ]} />
      <SelectInput source="state" choices={[
        { id: 'disabled', name: 'disabled' },
        { id: 'enabled', name: 'enabled' },
      ]} />
      <TextInput source="params" />
    </SimpleForm>
  </Create>
);
