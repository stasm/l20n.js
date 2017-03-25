import nodeResolve from 'rollup-plugin-node-resolve';

export default {
  format: 'es',
  intro: '{\n',
  outro: '\n}',
  plugins: [
    nodeResolve(),
  ]
};
