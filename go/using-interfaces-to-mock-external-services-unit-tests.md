# Using Interfaces to Mock External Services/Packages in Unit Tests

### From 100% integration testing to a nice mix of integration + unit tests
When I started building stuff with Go my primary approach to testing was
integration tests over unit tests. This was primarily because 1. I didn't
really know how to properly unit test (how to mock) in Go and 2. it's
pretty easy to integration test nowadays thanks to tools like Docker and Docker
Compose. I'd just slap together an integration test environment in a
`docker-compose.yml` file with a MySQL service or a canned HTTP API and test
full route handlers with external dependencies.

There is some downside to only using integration tests. Unit tests, in
comparison to integration tests, are practically instant. If you don't have a
good suite of unit tests you miss out on having a quick feedback loop of coding
& testing.

It's great to have unit tests you can run repeatedly on file save with
integration tests that can run in a post-commit hook and in CI.

### Unit Testing: How it's done in Go
Unit testing means no external dependencies - mock 'em. The idiomatic way to
implement mock functionality in Go is to use interfaces.

Lets say you've got a package that implements database fetching functionality.

```go
package dataloaders

import (
	"github.com/cflynn07/jwt-bcrypt-example/database"
	"github.com/cflynn07/jwt-bcrypt-example/types"
)

// GetUser returns a single record from the `users` table
func GetUser(username string) (*types.User, error) {
	user := &types.User{}
	result := database.DB.Where("username = ?", username).First(user)
	return user, result.Error
}
```

And you've got a REST API route handler that uses it.

```go
package handlers

import (
	"github.com/cflynn07/til-example/dataloaders"
	"github.com/cflynn07/til-example/types"
)

type UserReq struct {
  Username string `json:"username"`
}

func getUser(w http.ResponseWriter, r *http.Request) {
  w.Header().Set("content-type", "application/json")

  var ur UserReq
	err := json.NewDecoder(r.Body).Decode(&user)
  if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte(`{"error":"bad request"}`))
    return
  }

	if ur.Username == "" {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte(`{"error":"username required"}`))
		return
	}

  var user types.User
	user, err := dataloaders.GetUser(ur.Username)
  if err != nil {
		w.Write([]byte(`{"error":"user not found"}`))
    return
  }
  
	w.WriteHeader(http.StatusOK)
  json.NewEncoder(w).Encode(ur)
}
```

As the package code is currently written, an invocation of
`dataloaders.GetUser` from a test will use the live instance of the database
client library and make a real request to a database service. The idiomatic way
to handle unit testing this in Go is to make an interface that wraps just the
functionality of the database client that we want to use. In production use an
implementation of that interface that calls the actual database client, and
swap that implementation out when unit testing for one that uses a mock.

```go
package handlers

import (
	"github.com/cflynn07/til-example/dataloaders"
	"github.com/cflynn07/til-example/types"
)

type SQLDB interface {
  GetUser(username string) (*types.User, error)
}

type liveDB struct {}

func (ldb *liveDB) GetUser(username string) (*types.User, error) {
  return dataloaders.GetUser(username)
}

// exported so we can reassign from handlers_test package
var DB SQLDB

func init() {
  db = liveDB{}
}

type UserReq struct {
  Username string `json:"username"`
}

func getUser(w http.ResponseWriter, r *http.Request) {
  w.Header().Set("content-type", "application/json")

  var ur UserReq
	err := json.NewDecoder(r.Body).Decode(&user)
  if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte(`{"error":"bad request"}`))
    return
  }

	if ur.Username == "" {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte(`{"error":"username required"}`))
		return
	}

  var user types.User
	user, err := db.GetUser(ur.Username)
  if err != nil {
		w.Write([]byte(`{"error":"user not found"}`))
    return
  }
  
	w.WriteHeader(http.StatusOK)
  json.NewEncoder(w).Encode(ur)
}
```

Then from `handlers_test`

```go
package handlers_test

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gorilla/mux"
	"github.com/cflynn07/jwt-bcrypt-example/handlers"
	"github.com/cflynn07/til-example/types"
  "github.com/stretchr/testify/assert"
)

var mockUser types.User

type mockDB struct {}

func (mdb *mockDB) GetUser(username string) (*types.User, error) {
  return mockUser, nil
}

func Router() *mux.Router {
	router := mux.NewRouter()
	router.HandleFunc("/user", handlers.GetUser).Methods("POST") // ignore that this should be a GET request
	return router
}

func TestGetUser(t *testing.T) {
  mockUser = types.User{
    Name:  "John"
    Email: "john@gmail.com"
  }
	handlers.DB = mockDB{}

	request, _ := http.NewRequest("POST", "/user", strings.NewReader("{\"username\":\"john\"}"))
	response := httptest.NewRecorder()
	Router().ServeHTTP(response, request)
	assert.Equal(t, 200, response.Code, "OK response is expected")
	assert.Equal(t, "application/json", response.Result().Header["Content-Type"][0], "http content-type header response is expected")

  body, _ := ioutil.ReadAll(response.Result().Body)
  expectedBody = "{\"name\":\"john\",\"email\":\"john@gmail.com\"}"
	assert.Equal(t, expectedBody, string(body), "body does not match expected")
}
```

###### useful blog post on unit testing with interfaces
https://blog.learngoprogramming.com/how-to-mock-in-your-go-golang-tests-b9eee7d7c266
