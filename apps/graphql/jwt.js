const { request, gql } = require("graphql-request");

const query = gql`
  mutation ViewerLogin($input: AuthenticateInput!) {
    authenticate(input: $input) {
      jwtToken
    }
  }
`;

const user = {
  username: "test@test.com",
  password: "test123",
};

request(process.env.GRAPHQL_URL || "http://localhost:5000/graphql", query, {
  input: user,
})
  .then((res) => {
    console.info(
      `Paste this following into your GraphiQL editor's REQUEST HEADERS section`
    );
    console.info(
      `
{
"Authorization": "Bearer ${res.authenticate.jwtToken}"
}

    `
    );
  })
  .catch((e) => console.error(e));
