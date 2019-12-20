import * as React from 'react';
import {
  ArrayInput,
  Create,
  Datagrid,
  DateField,
  Edit,
  Filter,
  FormDataConsumer,
  List,
  SelectInput,
  SimpleForm,
  SimpleFormIterator,
  TextField,
  TextInput,
} from 'react-admin';
import { StyledDatagrid } from '../partials';

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
  </Filter>
);

export const RobotList = props => (
  <List filters={<RobotFilter />} {...props}>
    <StyledDatagrid rowClick="edit">
      <TextField source="id" />
      <TextField source="name" />
      <TextField source="strategy" />
      <TextField source="params" />
      <TextField source="state" />
      <DateField source="created_at" />
      <DateField source="updated_at" />
    </StyledDatagrid>
  </List>
);

export const RobotEdit = props => (
  <Edit {...props}>
    <SimpleForm>
      <TextField source="id" />
      <TextInput source="name" />
      <StrategySelect />
      <StateSelect />
      <TextInput multiline source="params" format={i => JSON.stringify(i)} />
    </SimpleForm>
  </Edit>
);

export const RobotCreate = props => (
  <Create {...props}>
    <SimpleForm>
      <TextInput source="name" />
      <StrategySelect />
      <StateSelect />
      <ArrayInput source="_params" >
        <SimpleFormIterator>
          <TextInput source="key" />
          <FormDataConsumer>
            {({ formData, scopedFormData, getSource, ...rest }) =>
              scopedFormData && scopedFormData.key ? (
                  <TextInput
                      source={`params.${scopedFormData.key}`}
                      {...rest}
                  />
              ) : null
            }
          </FormDataConsumer>
        </SimpleFormIterator>
      </ArrayInput>
    </SimpleForm>
  </Create>
);
