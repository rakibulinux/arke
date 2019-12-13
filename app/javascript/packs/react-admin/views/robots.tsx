import * as React from 'react';
import {
  ArrayInput,
  AutocompleteInput,
  Create,
  Datagrid,
  DateField,
  Edit,
  Filter,
  List,
  ReferenceField,
  ReferenceInput,
  SelectInput,
  SimpleForm,
  SimpleFormIterator,
  TextField,
  TextInput
} from 'react-admin';

const StrategySelect = props => (
  <SelectInput source="strategy" choices={[
    { id: 'copy', name: 'copy' },
    { id: 'orderback', name: 'orderback' },
    { id: 'fixedprice', name: 'fixedprice' },
    { id: 'microtrades', name: 'microtrades' },
  ]} {...props} />
);

const StateSelect = props => (
  <SelectInput source="state" choices={[
    { id: 'disabled', name: 'disabled' },
    { id: 'enabled', name: 'enabled' },
  ]} {...props} />
);

const UserInput = props => (
  <ReferenceInput source="user_id" reference="users" helperText="Unique user UID" {...props}>
    <AutocompleteInput optionText="uid" />
  </ReferenceInput>
);

const RobotFilter = props => (
  <Filter {...props}>
    <SelectInput source="state" choices={[
      { id: 'disabled', name: 'disabled' },
      { id: 'enabled', name: 'enabled' },
    ]} {...props} />
    <SelectInput source="strategy" choices={[
      { id: 'copy', name: 'copy' },
      { id: 'orderback', name: 'orderback' },
      { id: 'fixedprice', name: 'fixedprice' },
      { id: 'microtrades', name: 'microtrades' },
    ]} {...props} />
    <ReferenceInput source="user_id" reference="users" helperText="Unique user UID" {...props}>
      <SelectInput optionText="uid" />
    </ReferenceInput>
  </Filter>
);

export const RobotList = props => (
  <List filters={<RobotFilter />} {...props}>
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
      <TextField source="id" />
      <UserInput />
      <TextInput source="name" />
      <StrategySelect />
      <StateSelect />
      <TextInput source="params" />
    </SimpleForm>
  </Edit>
);

export const RobotCreate = props => (
  <Create {...props}>
    <SimpleForm>
      <UserInput />
      <TextInput source="name" />
      <StrategySelect />
      <StateSelect />
      <TextInput source="params" />
    </SimpleForm>
  </Create>
);
