import * as React from 'react';
import {
  SimpleForm,
  TextField,
  ArrayInput,
  SimpleFormIterator,
} from 'react-admin';
import { CardHeader, Card } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';

import {
  StyledSelectInput as SelectInput,
  StyledTextInput as TextInput,
} from '../partials';
import { capitalize } from '../helpers';

const formOptions = (...options: string[]) => options.map(o => ({ id: o, name: capitalize(o) }))

export const StrategySelect = props => (
  <SelectInput
    {...props}
    source='strategy'
    choices={formOptions('copy', 'orderback', 'fixedprice', 'microtrades')}
  />
);

export const StateSelect = props => (
  <SelectInput
    {...props}
    source='state'
    choices={formOptions('disabled', 'enabled')}
  />
);

const useCardStyle = makeStyles({
  card: {
    padding: '24px',
    alignItems: 'center',
    marginTop: '37px'
  }
});

const CandleSticks = props => (
  <ArrayInput {...props} source='candlesticks'>
    <SimpleFormIterator>
        <TextInput source='type' />
        <TextInput source='period' />
        <TextInput source='min_amount' />
        <TextInput source='max_amount' />
    </SimpleFormIterator>
  </ArrayInput>
);

const RobotForm = props => (
  <React.Fragment>
    {props.title &&  <CardHeader title={props.title} />}
    <SimpleForm {...props} margin='dense'>
      <Card className={useCardStyle(props).card}>
        <TextField source='id' />
        <TextInput source='name' />
        <StrategySelect />
        <StateSelect />
        <TextInput multiline source='params' format={i => JSON.stringify(i)} />
      </Card>

      <CandleSticks />
    </SimpleForm>
  </React.Fragment>
);

export default RobotForm;
