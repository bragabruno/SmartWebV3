import { 
  Button, 
  Card, 
  CardContent, 
  CardDescription, 
  CardHeader, 
  CardTitle,
  Badge,
  Input,
  Label,
  Separator,
  Icon,
  Plus,
  Search,
  Home,
  Users,
  Phone,
  BarChart3,
  Settings
} from '@smartwebv3/ui'

export default function DesignSystemShowcase() {
  return (
    <div className="min-h-screen bg-neutral-50">
      {/* Header */}
      <header className="border-b bg-white px-6 py-4">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-neutral-900">SmartWebV3 Design System</h1>
          <Badge variant="secondary">v0.1.0</Badge>
        </div>
      </header>

      {/* Main Content */}
      <main className="container mx-auto px-6 py-8">
        {/* Hero Section */}
        <div className="mb-12">
          <h2 className="mb-4 text-4xl font-bold text-neutral-900">
            Design System Components
          </h2>
          <p className="text-lg text-neutral-600">
            A comprehensive design system for the SmartWebV3 platform, ensuring consistency across all applications.
          </p>
        </div>

        {/* Components Grid */}
        <div className="grid gap-8 md:grid-cols-2 lg:grid-cols-3">
          {/* Buttons Section */}
          <Card>
            <CardHeader>
              <CardTitle>Buttons</CardTitle>
              <CardDescription>Interactive elements for user actions</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex flex-wrap gap-2">
                <Button>Default</Button>
                <Button variant="secondary">Secondary</Button>
                <Button variant="destructive">Destructive</Button>
                <Button variant="outline">Outline</Button>
                <Button variant="ghost">Ghost</Button>
                <Button variant="link">Link</Button>
              </div>
              <Separator />
              <div className="flex gap-2">
                <Button size="sm">Small</Button>
                <Button>Default</Button>
                <Button size="lg">Large</Button>
                <Button size="icon">
                  <Icon icon={Plus} />
                </Button>
              </div>
            </CardContent>
          </Card>

          {/* Form Elements */}
          <Card>
            <CardHeader>
              <CardTitle>Form Elements</CardTitle>
              <CardDescription>Input fields and form controls</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="email">Email</Label>
                <Input id="email" type="email" placeholder="john@example.com" />
              </div>
              <div className="space-y-2">
                <Label htmlFor="search">Search</Label>
                <div className="relative">
                  <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-neutral-400" />
                  <Input id="search" placeholder="Search leads..." className="pl-10" />
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Badges */}
          <Card>
            <CardHeader>
              <CardTitle>Badges</CardTitle>
              <CardDescription>Status indicators and labels</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="flex flex-wrap gap-2">
                <Badge>Default</Badge>
                <Badge variant="secondary">Secondary</Badge>
                <Badge variant="destructive">Destructive</Badge>
                <Badge variant="outline">Outline</Badge>
              </div>
            </CardContent>
          </Card>

          {/* Icons */}
          <Card>
            <CardHeader>
              <CardTitle>Icons</CardTitle>
              <CardDescription>Lucide React icon set integration</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-4 gap-4">
                <div className="flex flex-col items-center gap-2">
                  <Icon icon={Home} size="lg" className="text-primary-600" />
                  <span className="text-xs">Home</span>
                </div>
                <div className="flex flex-col items-center gap-2">
                  <Icon icon={Users} size="lg" className="text-primary-600" />
                  <span className="text-xs">Users</span>
                </div>
                <div className="flex flex-col items-center gap-2">
                  <Icon icon={Phone} size="lg" className="text-primary-600" />
                  <span className="text-xs">Phone</span>
                </div>
                <div className="flex flex-col items-center gap-2">
                  <Icon icon={BarChart3} size="lg" className="text-primary-600" />
                  <span className="text-xs">Analytics</span>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Typography */}
          <Card>
            <CardHeader>
              <CardTitle>Typography</CardTitle>
              <CardDescription>Text styles and hierarchy</CardDescription>
            </CardHeader>
            <CardContent className="space-y-2">
              <h1 className="text-3xl font-bold">Heading 1</h1>
              <h2 className="text-2xl font-semibold">Heading 2</h2>
              <h3 className="text-xl font-semibold">Heading 3</h3>
              <p className="text-base">Body text with regular weight</p>
              <p className="text-sm text-neutral-600">Small muted text</p>
            </CardContent>
          </Card>

          {/* Colors */}
          <Card>
            <CardHeader>
              <CardTitle>Color Palette</CardTitle>
              <CardDescription>Brand and semantic colors</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                <div className="flex items-center gap-2">
                  <div className="h-10 w-10 rounded bg-primary-500"></div>
                  <span className="text-sm">Primary</span>
                </div>
                <div className="flex items-center gap-2">
                  <div className="h-10 w-10 rounded bg-secondary-500"></div>
                  <span className="text-sm">Secondary</span>
                </div>
                <div className="flex items-center gap-2">
                  <div className="h-10 w-10 rounded bg-success-500"></div>
                  <span className="text-sm">Success</span>
                </div>
                <div className="flex items-center gap-2">
                  <div className="h-10 w-10 rounded bg-warning-500"></div>
                  <span className="text-sm">Warning</span>
                </div>
                <div className="flex items-center gap-2">
                  <div className="h-10 w-10 rounded bg-error-500"></div>
                  <span className="text-sm">Error</span>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Example Implementation */}
        <div className="mt-12">
          <h2 className="mb-6 text-3xl font-bold">Example Implementation</h2>
          <Card className="mx-auto max-w-4xl">
            <CardHeader>
              <CardTitle>Lead Management Dashboard</CardTitle>
              <CardDescription>
                A sample interface showing how components work together
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-6">
                {/* Search Bar */}
                <div className="flex gap-4">
                  <div className="relative flex-1">
                    <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-neutral-400" />
                    <Input placeholder="Search leads by name or company..." className="pl-10" />
                  </div>
                  <Button>
                    <Icon icon={Plus} className="mr-2" size="sm" />
                    Add Lead
                  </Button>
                </div>

                <Separator />

                {/* Lead Items */}
                <div className="space-y-4">
                  {[
                    { name: 'John\'s Plumbing', status: 'qualified', score: 85 },
                    { name: 'Elite Electric', status: 'contacted', score: 72 },
                    { name: 'Roof Masters Inc', status: 'new', score: 91 },
                  ].map((lead, index) => (
                    <div key={index} className="flex items-center justify-between rounded-lg border p-4">
                      <div>
                        <h4 className="font-semibold">{lead.name}</h4>
                        <p className="text-sm text-neutral-600">Score: {lead.score}/100</p>
                      </div>
                      <div className="flex items-center gap-2">
                        <Badge variant={
                          lead.status === 'qualified' ? 'default' :
                          lead.status === 'contacted' ? 'secondary' :
                          'outline'
                        }>
                          {lead.status}
                        </Badge>
                        <Button variant="ghost" size="sm">View Details</Button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </main>
    </div>
  )
}